# cython: infer_types

from typing import Dict, Iterable, List, Optional, Tuple
from cython.operator cimport dereference as deref
from functools import lru_cache
from io import BytesIO
import json
from libcpp.memory cimport make_shared, shared_ptr
from pathlib import Path
import regex


# We need the same splitting pattern and byte -> string remapping as GPT-2,
# so these are taken directly from:
#
# https://github.com/openai/gpt-2/blob/master/src/encoder.py
#
# See the LICENSE file for licensing information.


SPLIT_PATTERN = r"""'s|'t|'re|'ve|'m|'ll|'d| ?\p{L}+| ?\p{N}+| ?[^\s\p{L}\p{N}]+|\s+(?!\S)|\s+"""


@lru_cache()
def bytes_to_unicode() -> Dict[int, bytes]:
    """
    Returns list of utf-8 byte and a corresponding list of unicode strings.
    The reversible bpe codes work on unicode strings.
    This means you need a large # of unicode characters in your vocab if you want to avoid UNKs.
    When you're at something like a 10B token dataset you end up needing around 5K for decent coverage.
    This is a signficant percentage of your normal, say, 32K bpe vocab.
    To avoid that, we want lookup tables between utf-8 bytes and unicode strings.
    And avoids mapping to whitespace/control characters the bpe code barfs on.
    """
    bs = (
        list(range(ord("!"), ord("~") + 1))
        + list(range(ord("¡"), ord("¬") + 1))
        + list(range(ord("®"), ord("ÿ") + 1))
    )
    cs = bs[:]
    n = 0
    for b in range(2**8):
        if b not in bs:
            bs.append(b)
            cs.append(2**8 + n)
            n += 1
    cs = [chr(n).encode("utf-8") for n in cs]
    return dict(zip(bs, cs))

cdef class ByteBPEProcessor:
    cdef shared_ptr[Merges] _merges
    cdef dict _byte_decoder
    cdef dict _byte_encoder
    cdef object _split_pattern
    cdef dict _piece_to_id
    cdef dict _id_to_piece

    def __init__(self, vocab: Dict[str, int], merges: List[Tuple[str, str]]):
        self._byte_encoder = bytes_to_unicode()
        self._byte_decoder = {v.decode("utf-8"): k for k, v in self._byte_encoder.items()}
        self._split_pattern = regex.compile(SPLIT_PATTERN)
        self._piece_to_id = vocab
        self._id_to_piece = {v: k for k, v in vocab.items()}
        cdef vector[pair[string, string]] c_merges
        for p1, p2 in merges:
            c_merges.push_back(pair[string, string](p1.encode('utf-8'), p2.encode('utf-8')))
        self._merges = make_shared[Merges](c_merges)

    def __copy__(self):
        return ByteBPEProcessor(vocab=self.vocab, merges=self.merges)

    def __deepcopy__(self, memo):
        # We don't need a deepcopy of the vocab and merges dicts as their
        # contents will be copied into a backing store in the c'tor.
        return ByteBPEProcessor(vocab=self.vocab, merges=self.merges)

    @staticmethod
    def load_from_files(*, vocab: Path, merges: Path) -> ByteBPEProcessor:
        """Construct a processor from the given vocabulary and merges files."""
        with open(vocab, encoding="utf-8") as f:
            vocab = json.load(f)
        with open(merges, encoding="utf-8") as f:
            version = f.readline()
            if not version.startswith("#version: 0.2"):
                raise ValueError(f"Only version 0.2 of the merges format is supported, was: {version.strip()}")
            merges = []
            for line in f:
                merge = line.strip().split(" ")
                if len(merge) != 2:
                    raise ValueError(f"Merge must consist of 2 items, was {len(merge)}: {line.strip()}")
                merges.append(merge)
        return ByteBPEProcessor(vocab, merges)

    def decode_from_ids(self, ids: Iterable[int]) -> str:
        """
        Decode piece identifiers into string.

            ids (Iterable[int]): piece identifiers.
            RETURNS (str): decoded string.
        """
        decoded = BytesIO()
        for piece_id in ids:
            piece = self._id_to_piece.get(piece_id, None)
            if piece is None:
                raise ValueError(f"Unknown piece identifier: {piece_id}")
            decoded.write(bytes([self._byte_decoder[cp] for cp in list(piece)]))

        return decoded.getvalue().decode("utf-8")

    def encode(self, text: str) -> Tuple[List[int], List[str]]:
        """
        Split a text into pieces.

            text: The text to split.
            RETURNS: A pair of pieces and piece identifiers.
        """
        pieces = self.encode_as_pieces(text)
        return self._pieces_to_ids(pieces), pieces

    def encode_as_ids(self, text: str) -> List[int]:
        """
        Split a text into pieces, returning piece identifiers.

            text: The text to split.
            RETURNS: Piece identifiers.
        """
        pieces = self.encode_as_pieces(text)
        return self._pieces_to_ids(pieces)

    def encode_as_pieces(self, text: str) -> List[str]:
        """
        Split a text into pieces, returning piece pieces.

            text: The text to split.
            RETURNS: Piece pieces.
        """
        pieces = []
        for token in regex.findall(self._split_pattern, text):
            token_bytes = [self._byte_encoder[b] for b in token.encode("utf-8")]
            merged = deref(self._merges).apply_merges(token_bytes)
            pieces.extend(merge.decode("utf-8") for merge in merged)
        return pieces

    @property
    def merges(self) -> List[Tuple[str, str]]:
        """Get all merges."""
        merges_bytes = deref(self._merges).merges()
        return [(m1.decode('utf-8'), m2.decode('utf-8')) for m1, m2 in merges_bytes]

    def piece_id(self, piece: str) -> Optional[int]:
        """Get the identifier for a piece."""
        return self._piece_to_id.get(piece)

    @property
    def vocab(self) -> Dict[str, int]:
        """Get a copy of the vocabulary."""
        return dict(self._piece_to_id)

    def _pieces_to_ids(self, pieces):
        piece_ids = []
        for piece in pieces:
            piece_id = self._piece_to_id.get(piece)
            if piece_id is None:
                raise ValueError(f"Piece is not in vocabulary: {piece}")
            piece_ids.append(piece_id)

        return piece_ids

    def __reduce__(self):
        return (unpickle_byte_bpe_processor, (self.vocab, self.merges,))

def unpickle_byte_bpe_processor(vocab: Dict[str, int],
                                merges: List[Tuple[str, str]]) -> ByteBPEProcessor:
    return ByteBPEProcessor(vocab, merges)
