from cutlery import WordPieceProcessor
from pathlib import Path
import pytest


@pytest.fixture(scope="module")
def test_dir(request):
    return Path(request.fspath).parent


@pytest.fixture
def toy_processor_from_file(test_dir):
    return WordPieceProcessor.from_file(str(test_dir / "toy-word-pieces.txt"))


@pytest.fixture
def toy_processor():
    return WordPieceProcessor(["voor", "##tie", "coördina", "##kom", "##en"])


def test_can_get_initial(toy_processor):
    assert toy_processor.get_initial("voor") == 0
    assert toy_processor.get_initial("onbek") == None


def test_word_piece_processor_small(toy_processor):
    assert toy_processor.encode("voor") == ([0], ["voor"])
    assert toy_processor.encode("voorman") == ([0, -1], ["voor", None])
    assert toy_processor.encode("coördinatie") == ([2, 1], ["coördina", "##tie"])
    assert toy_processor.encode("voorkomen") == ([0, 3, 4], ["voor", "##kom", "##en"])


def test_to_list(toy_processor):
    assert toy_processor.to_list() == ["voor", "##tie", "coördina", "##kom", "##en"]


def test_from_file(toy_processor_from_file):
    assert toy_processor_from_file.to_list() == [
        "voor",
        "##tie",
        "coördina",
        "##kom",
        "##en",
    ]
