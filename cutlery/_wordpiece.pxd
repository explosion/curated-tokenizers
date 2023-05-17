from cython cimport size_t
from libcpp.string cimport string
from libcpp.unordered_map cimport unordered_map
from libcpp.vector cimport vector

cdef extern from "wordpiece.hh":
    cdef cppclass Piece:
        string piece
        bint is_initial
        Piece(const string& piece, bint initial)

cdef class WordPieceProcessor:
    cdef unordered_map[string, size_t] initial_piece_to_id
    cdef unordered_map[string, size_t] continuation_piece_to_id
    cdef vector[Piece] id_to_piece
