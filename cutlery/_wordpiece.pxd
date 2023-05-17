from cython cimport size_t
from libcpp.string cimport string
from libcpp.unordered_map cimport unordered_map
from libcpp.vector cimport vector

cdef class WordPieceProcessor:
    cdef unordered_map[string, size_t] initial_piece_to_id
    cdef unordered_map[size_t, string] id_to_initial_piece
    cdef unordered_map[string, size_t] continuation_piece_to_id
    cdef unordered_map[size_t, string] id_to_continuation_piece
