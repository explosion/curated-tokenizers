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
                self.id_to_piece.push_back(Piece(byte_array, False))
            else:
                byte_array = piece.encode('utf8')
                self.initial_piece_to_id[byte_array] = idx
                self.id_to_piece.push_back(Piece(byte_array, True))

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

    def decode(self, pieces: Iterable[int]) -> str:
        """
        Decode token piece identifiers into string. Raises a `ValueError` 
        if any of the identifiers are invalid.

            ids (Iterable[int]): Piece IDs.
            RETURNS (str): Decoded string.
        """
        token_pieces = [self.lookup_piece_id(id)[0] for id in pieces]
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

    def lookup_piece_id(self, piece: int) -> Tuple[str, bool]:
        """
        Returns the piece string (without any prefix) for a given piece identifier 
        and a boolean identifying if it is an initial piece. Raises a `ValueError` if 
        any of the identifiers are invalid.

            piece (int): Piece ID.
            RETURNS (Tuple[str, bool]): Piece string and a boolean identifying if
                it is an initial piece.
        """
        cdef Piece* ptr_piece
        if self.is_valid_piece_id(piece):
            ptr_piece = &self.id_to_piece[piece]
            return (ptr_piece[0].piece.decode('utf8'), ptr_piece[0].is_initial) 
        else:
            raise ValueError(f"invalid piece identifier `{piece}`")

    def is_valid_piece_id(self, piece: int) -> bool:
        """
        Returns True if the piece identifier is valid, False otherwise.

            piece (int): Piece ID.
            RETURNS (bool): Is valid.
        """
        return 0 <= piece <= self.id_to_piece.size() - 1

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
