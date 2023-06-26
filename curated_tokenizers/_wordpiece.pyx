from typing import List, Tuple, Iterable, Optional
from cython.operator cimport dereference as deref
from libcpp cimport pair

cdef struct PieceMatch:
    bint found
    int prefix_len
    int piece_id

cdef class WordPieceProcessor:
    cdef PieceStorage _pieces

    def __init__(self, pieces: List[str]):
        self._pieces = PieceStorage()

        for idx, piece in enumerate(pieces):
            is_initial = not piece.startswith("##")
            byte_array = piece[2:].encode('utf8') if not is_initial else piece.encode('utf8')
            self._pieces.add_piece(byte_array, is_initial)

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
        prefix = ""
        cdef PieceMatch match
        is_initial = True
        while token:
            match = self._find_longest_prefix(token, is_initial)
            if not match.found:
                token_ids.append(-1)
                token_pieces.append(None)
                return token_ids, token_pieces
            token_ids.append(match.piece_id)
            token_pieces.append(f"{prefix}{token[:match.prefix_len]}")
            token = token[match.prefix_len:]
            is_initial = False
            prefix = "##"
        return token_ids, token_pieces

    def decode(self, pieces: Iterable[int]) -> str:
        """
        Decode token piece identifiers into string. Raises a `ValueError` 
        if any of the identifiers are invalid.

            ids (Iterable[int]): Piece IDs.
            RETURNS (str): Decoded string.
        """
        token_pieces = []
        for piece_id in pieces:
            piece = self.id_to_piece(piece_id)
            if piece is None:
                raise ValueError(f"Piece ID `{piece_id}` is invalid")
            else:
                token_pieces.append(piece[0])
        return "".join(token_pieces)

    def get_initial(self, piece: str) -> Optional[int]:
        """
        Returns the ID for the given initial piece, or `None` if
        the string isn't an initial piece.

            piece (str): Initial piece string.
            RETURNS (Optional[int]): Piece ID or None
        """
        try:
            return self._pieces.piece_to_id(Piece(piece.encode('utf8'), True))
        except RuntimeError:
            return None

    def id_to_piece(self, piece: int) -> Tuple[str, bool]:
        """
        Returns the piece string (without any prefix) for a given piece identifier 
        and a boolean identifying if it is an initial piece. Returns `None` if the 
        piece identifier is invalid.

            piece (int): Piece ID.
            RETURNS (Optional[Tuple[str, bool]]): 
                Piece string and a boolean identifying if it is an initial piece,
                or None
        """
        cdef const Piece* ptr_piece
        try:
            ptr_piece = &self._pieces.id_to_piece(piece)
            return (ptr_piece[0].piece.decode('utf8'), ptr_piece[0].is_initial) 
        except RuntimeError:
            return None

    def is_valid_piece_id(self, piece: int) -> bool:
        """
        Returns True if the piece identifier is valid, False otherwise.

            piece (int): Piece ID.
            RETURNS (bool): Is valid.
        """
        return 0 <= piece <= self._pieces.size() - 1

    @staticmethod
    def from_file(filename: str) -> WordPieceProcessor:
        with open(filename, encoding="utf8") as f:
            pieces = [line.strip() for line in f]
        return WordPieceProcessor(pieces)

    def to_list(self):
        pieces = [None] * self._pieces.size()
        cdef Piece piece
        for i in range(self._pieces.size()):
            piece = self._pieces._id_to_piece[i]
            if piece.is_initial:
                pieces[i] = piece.piece.decode('utf8')
            else:
                pieces[i] = f"##{piece.piece.decode('utf8')}"

        return pieces

    cdef PieceMatch _find_longest_prefix(self, str token, bint is_initial):
        cdef PieceMatch match
        match.found = False

        cdef Piece piece
        for prefix_len in reversed(range(len(token) + 1)): 
            piece = Piece(token[:prefix_len].encode("utf8"), is_initial)
            idx = self._pieces.try_piece_to_id(piece)
            if idx != -1:
                match.found = True
                match.prefix_len = prefix_len
                match.piece_id = idx
                return match

        return match