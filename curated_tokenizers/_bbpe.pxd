from libcpp.utility cimport pair
from libcpp.vector cimport vector


cdef extern from "merges.hh":
    cdef cppclass Merge:
        pair[int, int] merge
        int merged_id

    cdef cppclass Merges:
        Merges(const vector[Merge]& merges)
        vector[int] apply_merges(vector[int] ids) const
        vector[pair[int, int]] merges() const