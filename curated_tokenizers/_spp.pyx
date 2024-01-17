from cython.operator cimport dereference as deref

from pathlib import Path
from typing import List, Optional, Tuple

from .types import FileLike


cdef class SentencePieceProcessor:
    def __cinit__(self):
        self.spp.reset(new CSentencePieceProcessor())

    def __init__(self):
        pass

    def __len__(self):
        _check_status(deref(self.spp).status())
        return deref(self.spp).GetPieceSize()

    def __copy__(self):
        return SentencePieceProcessor.from_protobuf(self.to_protobuf())

    def __deepcopy__(self, memo):
        result = SentencePieceProcessor.from_protobuf(self.to_protobuf())
        memo[id(self)] = result
        return result

    @staticmethod
    def from_file(file: FileLike):
        """
        Constructs a SentencePieceProcessor by loading a serialized model from
        disk.

        When the argument is a file object, the caller is responsible for
        closing it.

            file (FileLike): Model file.
        """
        cdef SentencePieceProcessor processor
        if isinstance(file, Path) or isinstance(file, str):
            processor = SentencePieceProcessor.__new__(SentencePieceProcessor)
            _check_status(deref(processor.spp).Load(str(file).encode("utf-8")))
            return processor
        else:
            return SentencePieceProcessor.from_protobuf(file.read())

    @staticmethod
    def from_protobuf(bytes protobuf):
        """
        Constructs a SentencePieceProcessor by loading a serialized model from
        a protocol buffer.

            protobuf (bytes): Byte array representing the model's serialized
                protocol buffer.
        """
        cdef SentencePieceProcessor processor = SentencePieceProcessor.__new__(SentencePieceProcessor)
        if len(protobuf) == 0:
            # SentencePiece returns an empty protobuf for uninitialized models.
            return processor
        cdef string_view protobuf_view = string_view(protobuf, len(protobuf))
        _check_status(deref(processor.spp).LoadFromSerializedProto(protobuf_view))
        return processor

    def to_protobuf(self) -> bytes:
        """
        Serializes the SentencePieceProcessor to a protocol buffer.

            RETURNS (bytes): Byte array representing the model's serialized
                protocol buffer.
        """
        cdef string serialized = deref(self.spp).serialized_model_proto()
        return bytes(serialized)

    def decode_from_ids(self, list ids) -> str:
        """
        Decodes piece indentifiers to a string. Raises a `ValueError` if the
        list elements are not integers.

            ids (List[int]): Piece IDs.
            RETURNS (str): Decoded string.
        """
        cdef vector[int] c_ids
        for piece_id in ids:
            if not isinstance(piece_id, int):
                raise TypeError("Pieces must be of type `int` when decoding from ids")
            c_ids.push_back(piece_id)
        cdef string output
        _check_status(deref(self.spp).Decode(c_ids, &output))
        return output.decode("utf-8")

    def decode_from_pieces(self, list pieces) -> str:
        """
        Decodes piece tokens to a string. Raises a `ValueError` if the
        list elements are not strings.

            ids (List[str]): Piece tokens.
            RETURNS (str): Decoded string.
        """
        cdef vector[string] c_strings
        for piece in pieces:
            if not isinstance(piece, str):
                raise TypeError("Pieces must be of type `str` when decoding from pieces")
            c_strings.push_back(piece.encode("utf-8"))
        cdef string output
        _check_status(deref(self.spp).Decode(c_strings, &output))
        return output.decode("utf-8")

    def encode(self, str sentence) -> Tuple[List[int], List[str]]:
        """
        Encodes a string to piece indentifiers and piece tokens.

            sentence (str): Text to encode.
            RETURNS (Tuple[List[int], List[str]]): Piece IDs and piece tokens
                corresponding to the input text.
        """
        cdef SentencePieceText text = self._encode(sentence)

        cdef int idx
        cdef SentencePieceText_SentencePiece piece
        pieces = []
        ids = []
        for idx in range(text.pieces_size()):
            piece = text.pieces(idx)
            ids.append(piece.id())
            pieces.append(piece.piece().decode("utf-8"))

        return ids, pieces

    def encode_as_ids(self, str sentence) -> List[int]:
        """
        Encodes a string to piece indentifiers.

            sentence (str): Text to encode.
            RETURNS (List[int]): Piece IDs.
        """
        cdef SentencePieceText text = self._encode(sentence)

        cdef int idx
        ids = []
        for idx in range(text.pieces_size()):
            ids.append(text.pieces(idx).id())

        return ids

    def encode_as_pieces(self, str sentence) -> List[str]:
        """
        Encodes a string to piece tokens.

            sentence (str): Text to encode.
            RETURNS (List[str]): Piece tokens.
        """
        cdef SentencePieceText text = self._encode(sentence)

        cdef int idx
        cdef SentencePieceText_SentencePiece piece
        pieces = []
        for idx in range(text.pieces_size()):
            piece = text.pieces(idx)
            pieces.append(text.pieces(idx).piece().decode("utf-8"))

        return pieces

    def piece_to_id(self, str piece) -> Optional[int]:
        """
        Returns the piece identifier for a given piece token, or 
        `None` if the piece token is OOV.

            piece (str): Piece token.
            RETURNS (int): Piece ID or None.
        """
        piece_bytes = piece.encode("utf8")
        cdef string_view piece_view = string_view(piece_bytes, len(piece_bytes))
        _check_status(deref(self.spp).status())
        cdef int piece_id = deref(self.spp).PieceToId(piece_view)
        cdef int unk_id = self.unk_id()
        cdef str unk_piece = self.id_to_piece(unk_id)
        if piece_id == self.unk_id() and piece != unk_piece:
            return None
        else:
            return piece_id

    def id_to_piece(self, int piece_id) -> Optional[str]:
        """
        Returns the piece token for a given piece identifier, or
        `None` if the piece identifier is out-of-bounds.

            piece_id (int): Piece ID.
            RETURNS (str): Piece token or None.
        """
        _check_status(deref(self.spp).status())
        cdef int vocab_size = deref(self.spp).GetPieceSize()
        if not 0 <= piece_id < vocab_size:
            return None
        else:
            return deref(self.spp).IdToPiece(piece_id).decode("utf8")

    def bos_id(self) -> int:
        """Returns the piece identifier for the `bos` meta token."""
        _check_status(deref(self.spp).status())
        return deref(self.spp).bos_id()

    def eos_id(self) -> int:
        """Returns the piece identifier for the `eos` meta token."""
        _check_status(deref(self.spp).status())
        return deref(self.spp).eos_id()

    def pad_id(self) -> int:
        """Returns the piece identifier for the `pad` meta token."""
        _check_status(deref(self.spp).status())
        return deref(self.spp).pad_id()

    def unk_id(self) -> int:
        """Returns the piece identifier for the `unk` meta token."""
        _check_status(deref(self.spp).status())
        return deref(self.spp).unk_id()

    cdef SentencePieceText _encode(self, str sentence) except * :
        sentence_bytes = sentence.encode("utf-8")
        cdef SentencePieceText text;
        _check_status(deref(self.spp).Encode(sentence.encode("utf-8"), &text))
        return text

    def __reduce__(self):
        return (unpickle_sentence_piece_processor, (self.to_protobuf(),))

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

def unpickle_sentence_piece_processor(protobuf: bytes) -> SentencePieceProcessor:
    return SentencePieceProcessor.from_protobuf(protobuf)
