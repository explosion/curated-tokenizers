from libc.stdint cimport uint32_t
from libcpp.memory cimport shared_ptr
from libcpp.string cimport string

cdef extern from "builtin_pb/sentencepiece.pb.h" namespace "sentencepiece":
    cdef cppclass SentencePieceText_SentencePiece:
        uint32_t id() const
        const string &piece() const

    cdef cppclass SentencePieceText:
        const SentencePieceText_SentencePiece& pieces(int index) const;
        int pieces_size() const


cdef extern from "sentencepiece_processor.h" namespace "sentencepiece":
    cdef cppclass SentencePieceProcessor:
        SentencePieceProcessor()
        string EncodeAsSerializedProto(const string& filename)
        Status Encode(const string& input, SentencePieceText* spt)
        Status Load(string filename)

cdef extern from "sentencepiece_processor.h" namespace "sentencepiece::util":
    # Cython 3.0 has support for C++ enum classes. Until then, work around it.
    cdef cppclass StatusCode:
        pass

    cdef cppclass Status:
        StatusCode code() const
        const char* error_message() const

cdef extern from "sentencepiece_processor.h" namespace "sentencepiece::util::StatusCode":
    cdef StatusCode kOk



cdef class Processor:
    cdef shared_ptr[SentencePieceProcessor] spp