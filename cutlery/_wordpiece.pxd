from cython cimport size_t
from libcpp.string cimport string
from libcpp.unordered_map cimport unordered_map
from libcpp.vector cimport vector

cdef class WordPieceProcessor:
    cdef unordered_map[string, size_t] initial_pieces
    cdef unordered_map[string, size_t] continuation_pieces
    cdef list _id_to_piece
    cdef set _initial_piece_ids
