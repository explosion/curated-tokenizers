from cython.operator cimport dereference as deref
cimport numpy as np
import numpy

cdef class Processor:
    def __cinit__(self):
        self.spp.reset(new SentencePieceProcessor())

    def __init__(self):
        raise TypeError("This class cannot be instantiated directly.")

    @staticmethod
    def from_file(str filename):
        cdef Processor processor = Processor.__new__(Processor)
        cdef Status status = deref(processor.spp).Load(filename.encode("utf-8"))
        if <int> status.code() != <int> kOk:
            raise OSError(status.error_message().decode("utf-8"))
        return processor

    @staticmethod
    def from_protobuf(bytes protobuf):
        cdef Processor processor = Processor.__new__(Processor)
        cdef string_view protobuf_view = string_view(protobuf, len(protobuf))
        cdef Status status = deref(processor.spp).LoadFromSerializedProto(protobuf_view)
        if <int> status.code() != <int> kOk:
            raise ValueError(status.error_message().decode("utf-8"))
        return processor

    def to_protobuf(self):
        cdef string serialized = deref(self.spp).serialized_model_proto()
        return bytes(serialized)

    def encode(self, str sentence):
        cdef SentencePieceText text = self._encode(sentence)

        cdef int idx
        cdef SentencePieceText_SentencePiece piece
        cdef np.ndarray[uint32_t] ids = numpy.empty((text.pieces_size()), dtype="uint32")
        pieces = []
        for idx in range(text.pieces_size()):
            piece = text.pieces(idx)
            (<uint32_t *> ids.data)[idx] = piece.id()
            pieces.append(piece.piece().decode("utf-8"))

        return ids, pieces

    def encode_as_ids(self, str sentence):
        cdef SentencePieceText text = self._encode(sentence)

        cdef int idx
        cdef np.ndarray[uint32_t] ids = numpy.empty((text.pieces_size()), dtype="uint32")
        for idx in range(text.pieces_size()):
            (<uint32_t *> ids.data)[idx] = text.pieces(idx).id()

        return ids

    def encode_as_pieces(self, str sentence):
        cdef SentencePieceText text = self._encode(sentence)

        cdef int idx
        cdef SentencePieceText_SentencePiece piece
        pieces = []
        for idx in range(text.pieces_size()):
            piece = text.pieces(idx)
            pieces.append(text.pieces(idx).piece().decode("utf-8"))

        return pieces

    cdef SentencePieceText _encode(self, str sentence):
        sentence_bytes = sentence.encode("utf-8")
        cdef SentencePieceText text;
        cdef Status status = deref(self.spp).Encode(sentence.encode("utf-8"), &text)
        if <int> status.code() != <int> kOk:
            raise ValueError(status.error_message().decode("utf-8"))
        return text
