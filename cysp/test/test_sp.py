import numpy.testing
from pathlib import Path
import pytest

from cysp.sp import Processor


@pytest.fixture(scope="module")
def test_dir(request):
    return Path(request.fspath).parent


@pytest.fixture
def toy_model(test_dir):
    return Processor.from_file(str(test_dir / "toy.model"))


def test_load_proto(test_dir):
    with open(str(test_dir / "toy.model"), "rb") as f:
        data = f.read()
    spp = Processor.from_protobuf(data)
    _check_ids(spp)
    serialized_data = spp.to_protobuf()
    assert serialized_data == data


def test_load_unknown_file():
    with pytest.raises(OSError, match=r"No such file"):
        Processor.from_file("bogus.model")


def test_handles_nul_character(toy_model):
    ids, pieces = toy_model.encode("Test\0 nul")
    numpy.testing.assert_equal(ids, [239, 382, 0, 7, 24, 231])
    assert pieces == ["▁T", "est", "\0", "▁", "n", "ul"]


def test_encode(toy_model):
    ids, pieces = toy_model.encode("I saw a girl with a telescope.")
    numpy.testing.assert_equal(
        ids, [8, 465, 10, 947, 41, 10, 170, 168, 110, 28, 20, 143, 4]
    )
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


def _check_ids(spp):
    ids = spp.encode_as_ids("I saw a girl with a telescope.")
    numpy.testing.assert_equal(
        ids, [8, 465, 10, 947, 41, 10, 170, 168, 110, 28, 20, 143, 4]
    )
