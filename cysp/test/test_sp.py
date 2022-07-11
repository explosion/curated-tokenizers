import numpy.testing
from pathlib import Path
import pytest

from cysp.sp import Processor


@pytest.fixture(scope="module")
def test_dir(request):
    return Path(request.fspath).parent


def test_load_unknown_file():
    with pytest.raises(OSError, match=r"No such file"):
        Processor.load_file("bogus.model")


def test_toy_model(test_dir):
    spp = Processor.load_file(str(test_dir / "toy.model"))
    ids, pieces = spp.encode("I saw a girl with a telescope.")
    print(pieces)
    numpy.testing.assert_equal(ids, [8, 465, 10, 947, 41, 10, 170, 168, 110, 28, 20, 143, 4])
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
