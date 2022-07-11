from cython.operator cimport dereference as deref
cimport numpy as np
import numpy

cdef class Processor:
    def __cinit__(self):
        self.spp.reset(new SentencePieceProcessor())

    def __init__(self):
        raise TypeError("This class cannot be instantiated directly.")

    @staticmethod
    def load_file(str filename):
        cdef Processor processor = Processor.__new__(Processor)

        cdef Status status = deref(processor.spp).Load(filename.encode("utf-8"))
        if <int> status.code() != <int> kOk:
            raise OSError(status.error_message().decode("utf-8"))

        return processor

    def encode(self, sentence):
        sentence_bytes = sentence.encode("utf-8")
        cdef SentencePieceText text;
        cdef Status status = deref(self.spp).Encode(sentence.encode("utf-8"), &text)
        if <int> status.code() != <int> kOk:
            raise ValueError(status.error_message().decode("utf-8"))

        cdef int idx
        cdef SentencePieceText_SentencePiece piece
        cdef np.ndarray[uint32_t] ids = numpy.empty((text.pieces_size()), dtype="uint32")
        pieces = []
        for idx in range(text.pieces_size()):
            piece = text.pieces(idx)
            (<uint32_t *> ids.data)[idx] = piece.id()
            pieces.append(piece.piece().decode("utf-8"))

        return ids, pieces
