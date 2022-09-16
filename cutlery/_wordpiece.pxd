from cython cimport size_t
from libcpp.string cimport string
from libcpp.unordered_map cimport unordered_map

cdef class WordPieceProcessor:
    cdef unordered_map[string, size_t] initial_pieces
    cdef unordered_map[string, size_t] continuation_pieces
