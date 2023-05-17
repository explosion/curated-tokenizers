from cutlery import WordPieceProcessor
from pathlib import Path
import pytest


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
    "voor<unk>",
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
        assert toy_processor.encode(token) == output


def test_word_piece_processor_small_decode(toy_processor):
    for encoding, result in zip(EXAMPLE_ENCODINGS, EXAMPLE_DECODINGS):
        assert toy_processor.decode(encoding[0], unk_token="<unk>") == result


def test_to_list(toy_processor):
    assert toy_processor.to_list() == TOKEN_PIECES


def test_from_file(toy_processor_from_file):
    assert toy_processor_from_file.to_list() == TOKEN_PIECES


def test_initial_and_continuation(toy_processor):
    assert toy_processor.get_initial("voor") == 0
    with pytest.raises(KeyError):
        toy_processor.get_initial("##tie")

    assert toy_processor.get_continuation("##tie") == 1
    with pytest.raises(KeyError):
        toy_processor.get_continuation("coördina")


def test_is_initial_or_continuation_piece_id(toy_processor):
    assert [
        toy_processor.is_initial_piece_id(id) for id in range(len(TOKEN_PIECES))
    ] == [True, False, True, False, False]

    assert [
        toy_processor.is_continuation_piece_id(id) for id in range(len(TOKEN_PIECES))
    ] == [False, True, False, True, True]
