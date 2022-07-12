from libc.stdint cimport uint32_t
from libcpp.memory cimport shared_ptr
from libcpp.string cimport string
from libcpp.vector cimport vector

cdef extern from "builtin_pb/sentencepiece.pb.h" namespace "sentencepiece":
    cdef cppclass SentencePieceText_SentencePiece:
        uint32_t id() const
        const string & piece() const

    cdef cppclass SentencePieceText:
        const SentencePieceText_SentencePiece& pieces(int index) const;
        int pieces_size() const


cdef extern from "sentencepiece_processor.h" namespace "sentencepiece":
    cdef cppclass SentencePieceProcessor:
        SentencePieceProcessor()
        string EncodeAsSerializedProto(const string& filename)
        Status Decode(const vector[int]& ids, string *detokenized)
        Status Decode(const vector[string]& ids, string *detokenized)
        Status Encode(const string& input, SentencePieceText * spt)
        Status Load(const string& filename)
        Status LoadFromSerializedProto(string_view serialized);
        string serialized_model_proto() const


cdef extern from "sentencepiece_processor.h" namespace "absl":
    cdef cppclass string_view:
        string_view()
        string_view(const char * data, size_t len)


cdef extern from "sentencepiece_processor.h" namespace "sentencepiece::util":
    # Cython 3.0 has support for C++ enum classes. Until then, work around it.
    cdef cppclass StatusCode:
        pass

    cdef cppclass Status:
        StatusCode code() const
        const char * error_message() const

cdef extern from "sentencepiece_processor.h" namespace "sentencepiece::util::StatusCode":
    cdef StatusCode kOk



cdef class Processor:
    cdef shared_ptr[SentencePieceProcessor] spp

    cdef SentencePieceText _encode(self, str sentence) except *
