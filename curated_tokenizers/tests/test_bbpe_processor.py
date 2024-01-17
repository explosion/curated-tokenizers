import json
from pathlib import Path
from pickle import dumps, loads

import pytest

from curated_tokenizers import ByteBPEProcessor


@pytest.fixture(scope="module")
def test_dir(request):
    return Path(request.fspath).parent


@pytest.fixture
def vocab_path(test_dir):
    return test_dir / "robbert-vocab-1000.json"


@pytest.fixture
def merges_path(test_dir):
    return test_dir / "robbert-merges-1000.txt"


@pytest.fixture
def toy_processor(vocab_path, merges_path):
    return ByteBPEProcessor.load_from_files(
        vocab=vocab_path,
        merges=merges_path,
    )


EXAMPLE_TEXT = " Wij bezoeken alle provinciën."
EXAMPLE_PIECES = [
    "ĠWij",
    "Ġbez",
    "oeken",
    "Ġalle",
    "Ġpro",
    "v",
    "in",
    "c",
    "iÃ«n",
    ".",
]

EXAMPLE_PIECE_IDS = [280, 3377, 7095, 92, 1951, 253, 194, 311, 3698, 4]


def test_empty_processor():
    bbpe = ByteBPEProcessor({}, [])
    # An empty processor never merges, only recodes bytes.
    assert bbpe.encode_as_pieces("they'll visit Köln") == [
        "t",
        "h",
        "e",
        "y",
        "'",
        "l",
        "l",
        "Ġ",
        "v",
        "i",
        "s",
        "i",
        "t",
        "Ġ",
        "K",
        "Ã",
        "¶",
        "l",
        "n",
    ]


def test_can_decode(toy_processor):
    assert toy_processor.decode_from_ids(EXAMPLE_PIECE_IDS) == EXAMPLE_TEXT


def test_can_encode(toy_processor):
    assert toy_processor.encode(EXAMPLE_TEXT) == (EXAMPLE_PIECE_IDS, EXAMPLE_PIECES)


def test_can_encode_as_ids(toy_processor):
    assert toy_processor.encode_as_ids(EXAMPLE_TEXT) == EXAMPLE_PIECE_IDS


def test_can_encode_as_pieces(toy_processor):
    assert toy_processor.encode_as_pieces(EXAMPLE_TEXT) == EXAMPLE_PIECES


def test_rejects_incorrect_merges(test_dir):
    with pytest.raises(ValueError, match=r"Merge must consist of 2 items"):
        ByteBPEProcessor.load_from_files(
            vocab=test_dir / "robbert-vocab-1000.json",
            merges=test_dir / "incorrect-merges.txt",
        )


def test_id_to_piece_and_piece_to_id(toy_processor):
    assert toy_processor.piece_to_id("woord") == 4083
    assert toy_processor.piece_to_id("Ġwebsite") == 258
    assert toy_processor.piece_to_id("kglw") is None

    assert toy_processor.id_to_piece(207) == "ĠNederland"
    assert toy_processor.id_to_piece(113) == "Ġdoen"
    assert toy_processor.id_to_piece(99999) is None


def test_can_load_from_file_object(vocab_path, merges_path):
    with open(vocab_path, encoding="utf-8") as vocab:
        with open(merges_path, encoding="utf-8") as merges:
            toy_processor = ByteBPEProcessor.load_from_files(
                vocab=vocab,
                merges=merges,
            )
    assert toy_processor.encode(EXAMPLE_TEXT) == (EXAMPLE_PIECE_IDS, EXAMPLE_PIECES)


def test_pickle(toy_processor):
    serialized = dumps(toy_processor)
    deserialized = loads(serialized)
    assert isinstance(deserialized, ByteBPEProcessor)
    assert deserialized.vocab == toy_processor.vocab
    assert deserialized.merges == toy_processor.merges
