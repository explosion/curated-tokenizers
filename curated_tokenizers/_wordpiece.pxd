from cython cimport size_t
from libcpp.string cimport string
from libcpp.unordered_map cimport unordered_map
from libcpp.vector cimport vector

cdef extern from "wordpiece.hh":
    cdef cppclass Piece:
        string piece
        bint is_initial
        Piece()
        Piece(const string& piece, bint initial)

    cdef cppclass PieceStorage:
        vector[Piece] _id_to_piece

        PieceStorage()
        void add_piece(const string &piece, const bint is_initial)
        size_t size()
        const Piece &id_to_piece(const int id) except +
        size_t piece_to_id(const Piece &piece) except +
        int try_piece_to_id(const Piece &piece)

