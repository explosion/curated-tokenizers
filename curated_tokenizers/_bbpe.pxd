from libcpp.string cimport string
from libcpp.utility cimport pair
from libcpp.vector cimport vector


cdef extern from "merges.hh":
    cdef cppclass Merges:
        Merges(const vector[pair[string, string]]& merges)
        vector[string] apply_merges(vector[string] pieces) const
        vector[pair[string, string]] merges() const