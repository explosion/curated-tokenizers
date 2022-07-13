from cython.operator cimport dereference as deref
cimport numpy as np
import numpy

cdef class SentencePieceProcessor:
    def __cinit__(self):
        self.spp.reset(new CSentencePieceProcessor())

    def __init__(self):
        pass

    @staticmethod
    def from_file(str filename):
        cdef SentencePieceProcessor processor = SentencePieceProcessor.__new__(SentencePieceProcessor)
        _check_status(deref(processor.spp).Load(filename.encode("utf-8")))
        return processor

    @staticmethod
    def from_protobuf(bytes protobuf):
        cdef SentencePieceProcessor processor = SentencePieceProcessor.__new__(SentencePieceProcessor)
        cdef string_view protobuf_view = string_view(protobuf, len(protobuf))
        _check_status(deref(processor.spp).LoadFromSerializedProto(protobuf_view))
        return processor

    def to_protobuf(self):
        cdef string serialized = deref(self.spp).serialized_model_proto()
        return bytes(serialized)

    def decode_from_ids(self, np.ndarray[uint32_t] ids):
        cdef vector[int] c_ids
        cdef int idx
        for idx in range(len(ids)):
            c_ids.push_back((<uint32_t *> ids.data)[idx])
        cdef string output
        _check_status(deref(self.spp).Decode(c_ids, &output))
        return output.decode("utf-8")

    def decode_from_pieces(self, list pieces):
        cdef vector[string] c_strings
        for piece in pieces:
            if not isinstance(piece, str):
                raise TypeError("Pieces must be of type `str` when decoding from pieces")
            c_strings.push_back(piece.encode("utf-8"))
        cdef string output
        _check_status(deref(self.spp).Decode(c_strings, &output))
        return output.decode("utf-8")

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

    cdef SentencePieceText _encode(self, str sentence) except *:
        sentence_bytes = sentence.encode("utf-8")
        cdef SentencePieceText text;
        _check_status(deref(self.spp).Encode(sentence.encode("utf-8"), &text))
        return text

cdef _check_status(Status status):
    cdef code = <int> status.code()
    if code == <int> kOk:
        return
    elif code == <int> kNotFound:
        raise OSError(status.error_message().decode("utf-8"))
    elif code == <int> kInternal:
        raise RuntimeError(status.error_message().decode("utf-8"))
    else:
        raise ValueError(status.error_message().decode("utf-8"))
