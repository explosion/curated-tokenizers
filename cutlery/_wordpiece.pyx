from typing import List, Tuple, Iterable
from cython.operator cimport dereference as deref
from libcpp cimport pair

cdef struct PieceMatch:
    bint found
    int prefix_len
    int piece_id

cdef class WordPieceProcessor:
    def __init__(self, pieces: List[str]):
        for idx, piece in enumerate(pieces):
            if piece.startswith("##"):
                byte_array = piece[2:].encode('utf8')
                self.continuation_piece_to_id[byte_array] = idx
                self.id_to_continuation_piece[idx] = byte_array
            else:
                byte_array = piece.encode('utf8')
                self.initial_piece_to_id[piece.encode('utf8')] = idx
                self.id_to_initial_piece[idx] = byte_array

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
        cdef const unordered_map[string, size_t]* pieces = &self.initial_piece_to_id
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
            pieces = &self.continuation_piece_to_id
            prefix = "##"
        return token_ids, token_pieces

    def decode(self, pieces: Iterable[int], *, unk_token: str = "<unk>") -> str:
        """
        Decode piece identifiers into string. Invalid piece identifiers
        are replaced with the `unk_token` string.

            ids (Iterable[int]): Piece IDs.
            unk_token (str): Marker for unknown piece IDs.
            RETURNS (str): Decoded string.
        """
        token_pieces = [self.piece_id_to_str(id, unk_token=unk_token) for id in pieces]
        return "".join(token_pieces)

    def get_initial(self, piece: str) -> int:
        """
        Returns the ID for the given initial piece. Raises a `KeyError` if 
        the string isn't an initial piece.

            piece (str): Initial piece string.
            RETURNS (int): Piece ID.
        """
        cdef unordered_map[string, size_t].const_iterator iter
        iter = self.initial_piece_to_id.const_find(piece.encode('utf8'))
        if iter == self.initial_piece_to_id.end():
            raise KeyError(f"unknown initial piece `{piece}`")
        else:
            return deref(iter).second

    def get_continuation(self, piece: str) -> int:
        """
        Returns the ID for the given continuation piece. Raises a `KeyError` if 
        the string isn't an continuation piece.

            piece (str): Continuation piece string.
            RETURNS (int): Piece ID.
        """
        if piece[:2] != "##":
            raise KeyError(f"missing prefix in continuation piece `{piece}`")
        else:
            piece = piece[2:]
        cdef unordered_map[string, size_t].const_iterator iter
        iter = self.continuation_piece_to_id.const_find(piece.encode('utf8'))
        if iter == self.continuation_piece_to_id.end():
            raise KeyError(f"unknown continuation piece `{piece}`")
        else:
            return deref(iter).second

    def is_initial_piece_id(self, piece: int) -> bool:
        """
        Returns True if the piece identifier corresponds to an inital piece, False
        otherwise.

            piece (int): Piece ID.
            RETURNS (bool): Is initial.
        """
        cdef unordered_map[size_t, string].const_iterator iter
        iter = self.id_to_initial_piece.const_find(piece)
        return iter != self.id_to_initial_piece.end()

    def is_continuation_piece_id(self, piece: int) -> bool:
        """
        Returns True if the piece identifier corresponds to a continuation piece, False
        otherwise.

            piece (int): Piece ID.
            RETURNS (bool): Is continuation.
        """
        cdef unordered_map[size_t, string].const_iterator iter
        iter = self.id_to_continuation_piece.const_find(piece)
        return iter != self.id_to_continuation_piece.end()

    def piece_id_to_str(self, piece: int, *, unk_token: str = "<unk>") -> str:
        """
        Returns the piece string (without any prefix) for a given piece identifier. 
        Invalid piece identifiers return the `unk_token` string.

            piece (int): Piece ID.
            unk_token (str): Marker for unknown piece IDs.
            RETURNS (str): Piece string.
        """
        if piece < 0:
            return unk_token

        cdef unordered_map[size_t, string].const_iterator iter
        iter = self.id_to_initial_piece.const_find(piece)
        if iter != self.id_to_initial_piece.end():
            return deref(iter).second.decode('utf8')

        iter = self.id_to_continuation_piece.const_find(piece)
        if iter != self.id_to_continuation_piece.end():
            return deref(iter).second.decode('utf8')
        else:
            return unk_token

    def is_valid_piece_id(self, piece: int) -> bool:
        """
        Returns True if the piece identifier is valid, False otherwise.

            piece (int): Piece ID.
            RETURNS (bool): Is valid.
        """
        num_total_ids = self.initial_piece_to_id.size() + self.continuation_piece_to_id.size()
        return 0 <= piece <= num_total_ids - 1

    @staticmethod
    def from_file(filename: str) -> WordPieceProcessor:
        with open(filename, encoding="utf8") as f:
            pieces = [line.strip() for line in f]
        return WordPieceProcessor(pieces)

    def to_list(self):
        pieces = [None] * (self.initial_piece_to_id.size() + self.continuation_piece_to_id.size())

        for piece, idx in self.initial_piece_to_id:
            pieces[idx] = piece.decode('utf8')

        for piece, idx in self.continuation_piece_to_id:
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
