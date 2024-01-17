from pathlib import Path
from pickle import dumps, loads

import pytest

from curated_tokenizers import WordPieceProcessor

EXAMPLE_TOKENS = [
    "voor",
    "voorman",
    "coördinatie",
    "voorkomen",
]

EXAMPLE_ENCODINGS = [
    ([0], ["voor"]),
    ([0, -1], ["voor", None]),
    ([2, 1], ["coördina", "##tie"]),
    ([0, 3, 4], ["voor", "##kom", "##en"]),
]

EXAMPLE_DECODINGS = [
    "voor",
    "",  # Will raise an error.
    "coördinatie",
    "voorkomen",
]

TOKEN_PIECES = ["voor", "##tie", "coördina", "##kom", "##en"]


@pytest.fixture(scope="module")
def test_dir(request):
    return Path(request.fspath).parent


@pytest.fixture
def toy_processor_from_file(test_dir):
    return WordPieceProcessor.from_file(str(test_dir / "toy-word-pieces.txt"))


@pytest.fixture
def toy_processor():
    return WordPieceProcessor(TOKEN_PIECES)


def test_word_piece_processor_small_encode(toy_processor):
    for token, output in zip(EXAMPLE_TOKENS, EXAMPLE_ENCODINGS):
        y = toy_processor.encode(token)
        assert y == output


def test_word_piece_processor_small_decode(toy_processor):
    for encoding, result in zip(EXAMPLE_ENCODINGS, EXAMPLE_DECODINGS):
        if -1 in encoding[0]:
            with pytest.raises(RuntimeError):
                toy_processor.decode(encoding[0])
        else:
            assert toy_processor.decode(encoding[0]) == result


def test_to_list(toy_processor):
    assert toy_processor.to_list() == TOKEN_PIECES


def test_from_file(toy_processor_from_file):
    assert toy_processor_from_file.to_list() == TOKEN_PIECES


def test_get_initial(toy_processor):
    assert toy_processor.get_initial("voor") == 0
    with pytest.raises(RuntimeError):
        toy_processor.get_initial("##tie")


def test_piece_id_valid(toy_processor):
    assert toy_processor.is_valid_piece_id(-1) == False
    assert toy_processor.is_valid_piece_id(0) == True
    assert toy_processor.is_valid_piece_id(len(TOKEN_PIECES)) == False
    assert toy_processor.is_valid_piece_id(len(TOKEN_PIECES) - 1) == True


def test_pickle(toy_processor):
    serialized = dumps(toy_processor)
    deserialized = loads(serialized)
    assert isinstance(deserialized, WordPieceProcessor)
    assert deserialized.to_list() == toy_processor.to_list()
