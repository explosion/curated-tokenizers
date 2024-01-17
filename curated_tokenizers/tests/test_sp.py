from pathlib import Path
from pickle import dumps, loads

import pytest

from curated_tokenizers import SentencePieceProcessor


@pytest.fixture(scope="module")
def test_dir(request):
    return Path(request.fspath).parent


@pytest.fixture
def toy_model(test_dir):
    return SentencePieceProcessor.from_file(str(test_dir / "toy.model"))


def test_load_proto(test_dir):
    with open(str(test_dir / "toy.model"), "rb") as f:
        data = f.read()
    spp = SentencePieceProcessor.from_protobuf(data)
    _check_ids(spp)
    serialized_data = spp.to_protobuf()
    assert serialized_data == data

    # Zero-length buffer.
    spp = SentencePieceProcessor.from_protobuf(bytes())
    assert spp.to_protobuf() == bytes()


def test_load_unknown_file():
    with pytest.raises(OSError, match=r"No such file"):
        SentencePieceProcessor.from_file("bogus.model")


def test_handles_nul_character(toy_model):
    ids, pieces = toy_model.encode("Test\0 nul")
    assert ids == [239, 382, 0, 7, 24, 231]
    assert pieces == ["▁T", "est", "\0", "▁", "n", "ul"]


def test_decode_from_ids(toy_model):
    decoded = toy_model.decode_from_ids(
        [8, 465, 10, 947, 41, 10, 170, 168, 110, 28, 20, 143, 4]
    )
    assert decoded == "I saw a girl with a telescope."


def test_decode_from_pieces(toy_model):
    decoded = toy_model.decode_from_pieces(
        [
            "▁I",
            "▁saw",
            "▁a",
            "▁girl",
            "▁with",
            "▁a",
            "▁t",
            "el",
            "es",
            "c",
            "o",
            "pe",
            ".",
        ]
    )
    assert decoded == "I saw a girl with a telescope."


def test_decode_with_pieces_rejects_inccorect_type(toy_model):
    with pytest.raises(TypeError):
        toy_model.decode_from_pieces("test")
    with pytest.raises(TypeError):
        toy_model.decode_from_pieces([1, 2, 3])


def test_encode(toy_model):
    ids, pieces = toy_model.encode("I saw a girl with a telescope.")
    assert ids == [8, 465, 10, 947, 41, 10, 170, 168, 110, 28, 20, 143, 4]
    assert pieces == [
        "▁I",
        "▁saw",
        "▁a",
        "▁girl",
        "▁with",
        "▁a",
        "▁t",
        "el",
        "es",
        "c",
        "o",
        "pe",
        ".",
    ]


def test_encode_as_ids(toy_model):
    _check_ids(toy_model)


def test_encode_as_pieces(toy_model):
    pieces = toy_model.encode_as_pieces("I saw a girl with a telescope.")
    assert pieces == [
        "▁I",
        "▁saw",
        "▁a",
        "▁girl",
        "▁with",
        "▁a",
        "▁t",
        "el",
        "es",
        "c",
        "o",
        "pe",
        ".",
    ]


def test_uninitialized_model():
    spp = SentencePieceProcessor()
    with pytest.raises(RuntimeError):
        spp.encode("I saw a girl with a telescope.")
    with pytest.raises(RuntimeError):
        spp.encode_as_ids("I saw a girl with a telescope.")
    with pytest.raises(RuntimeError):
        spp.encode_as_pieces("I saw a girl with a telescope.")
    with pytest.raises(RuntimeError):
        spp.decode_from_pieces(["▁I"])
    with pytest.raises(RuntimeError):
        spp.decode_from_ids([8])
    with pytest.raises(RuntimeError):
        spp.bos_id()
    with pytest.raises(RuntimeError):
        spp.eos_id()
    with pytest.raises(RuntimeError):
        spp.unk_id()
    with pytest.raises(RuntimeError):
        spp.pad_id()


def _check_ids(spp):
    assert len(spp) == 1000
    assert spp.bos_id() == 1
    assert spp.eos_id() == 2
    assert spp.unk_id() == 0
    assert spp.pad_id() == -1  # Disabled in this model.
    ids = spp.encode_as_ids("I saw a girl with a telescope.")
    assert ids == [8, 465, 10, 947, 41, 10, 170, 168, 110, 28, 20, 143, 4]


def test_id_to_piece_and_piece_to_id(toy_model):
    assert toy_model.piece_to_id("<s>") == toy_model.bos_id()
    assert toy_model.piece_to_id("</s>") == toy_model.eos_id()
    assert toy_model.piece_to_id("<unk>") == toy_model.unk_id()
    assert toy_model.piece_to_id("qotsa") == toy_model.unk_id()

    assert toy_model.id_to_piece(toy_model.bos_id()) == "<s>"
    assert toy_model.id_to_piece(toy_model.eos_id()) == "</s>"
    assert toy_model.id_to_piece(toy_model.unk_id()) == "<unk>"
    with pytest.raises(ValueError):
        toy_model.id_to_piece(-1)
    with pytest.raises(ValueError):
        toy_model.id_to_piece(len(toy_model))


def test_pickle(toy_model):
    serialized = dumps(toy_model)
    deserialized = loads(serialized)
    assert isinstance(deserialized, SentencePieceProcessor)
    assert deserialized.to_protobuf() == toy_model.to_protobuf()
