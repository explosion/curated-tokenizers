from pathlib import Path
from pickle import dumps, loads

import pytest

from curated_tokenizers import ByteBPEProcessor


@pytest.fixture(scope="module")
def test_dir(request):
    return Path(request.fspath).parent


@pytest.fixture
def toy_processor(test_dir):
    return ByteBPEProcessor.load_from_files(
        vocab=test_dir / "robbert-vocab-1000.json",
        merges=test_dir / "robbert-merges-1000.txt",
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


def test_pickle(toy_processor):
    serialized = dumps(toy_processor)
    deserialized = loads(serialized)
    assert isinstance(deserialized, ByteBPEProcessor)
    assert deserialized.vocab == toy_processor.vocab
    assert deserialized.merges == toy_processor.merges
