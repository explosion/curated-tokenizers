from typing import List, Tuple, Iterable
from cython.operator cimport dereference as deref
from libcpp cimport pair

cdef struct PieceMatch:
    bint found
    int prefix_len
    int piece_id

cdef class WordPieceProcessor:
    def __init__(self, pieces: List[str]):
        self._id_to_piece = []
        self._initial_piece_ids = set()
        for idx, piece in enumerate(pieces):
            if piece.startswith("##"):
                self.continuation_pieces[piece[2:].encode('utf8')] = idx
                self._id_to_piece.append(piece[2:])
            else:
                self.initial_pieces[piece.encode('utf8')] = idx
                self._id_to_piece.append(piece)
                self._initial_piece_ids.add(idx)

            assert idx == len(self._id_to_piece) - 1

    def encode(self, token: str) -> Tuple[List[int], List[str]]:
        """
        Encode a token using word pieces. The piece identifiers are
        returned. If no piece could be found for a suffix, the special
        piece identifier `-1` is used.

            token (str): The token to encode as pieces.
            RETURNS (Tuple[List[int], List[str]]): Piece identifiers and token pieces.
        """
        token_ids = []
        token_pieces = []
        cdef const unordered_map[string, size_t]* pieces = &self.initial_pieces
        prefix = ""
        cdef PieceMatch match
        while token:
            match = _find_longest_prefix(pieces, token)
            if not match.found:
                token_ids.append(-1)
                token_pieces.append(None)
                return token_ids, token_pieces
            token_ids.append(match.piece_id)
            token_pieces.append(f"{prefix}{token[:match.prefix_len]}")
            token = token[match.prefix_len:]
            pieces = &self.continuation_pieces
            prefix = "##"
        return token_ids, token_pieces

    def decode(self, pieces: Iterable[int], *, unk_token: str = "<unk>") -> str:
        """
        Decode piece identifiers into string. Invalid piece identifiers
        are replaced with the `unk_token` string.

            ids (Iterable[int]): Piece identifiers.
            RETURNS (str): Decoded string.
        """
        token_pieces = []
        for piece_id in pieces:
            if 0 <= piece_id < len(self._id_to_piece):
                token_pieces.append(self._id_to_piece[piece_id])
            else:
                token_pieces.append(unk_token)

        return "".join(token_pieces)

    def get_initial(self, piece: str) -> int:
        cdef unordered_map[string, size_t].const_iterator iter
        iter = self.initial_pieces.const_find(piece.encode('utf8'))
        if iter == self.initial_pieces.end():
            raise KeyError(f"unknown initial piece {piece}")
        else:
            return deref(iter).second

    def is_initial_piece_id(self, piece: int) -> bool:
        return piece in self._initial_piece_ids

    @staticmethod
    def from_file(filename: str) -> WordPieceProcessor:
        with open(filename, encoding="utf8") as f:
            pieces = [line.strip() for line in f]
        return WordPieceProcessor(pieces)

    def to_list(self):
        pieces = [None] * (self.initial_pieces.size() + self.continuation_pieces.size())

        for piece, idx in self.initial_pieces:
            pieces[idx] = piece.decode('utf8')

        for piece, idx in self.continuation_pieces:
            pieces[idx] = f"##{piece.decode('utf8')}"

        return pieces


cdef PieceMatch _find_longest_prefix(const unordered_map[string, size_t]* pieces, str token):
    cdef PieceMatch match
    cdef unordered_map[string, size_t].const_iterator idx
    match.found = False

    for prefix_len in reversed(range(len(token) + 1)): 
        idx = pieces.const_find(token[:prefix_len].encode("utf8"))
        if idx != pieces.end():
            match.found = True
            match.prefix_len = prefix_len
            match.piece_id = deref(idx).second
            return match

    return match
