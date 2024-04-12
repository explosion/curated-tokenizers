import json
from pathlib import Path
from pickle import dumps, loads

import pytest

from curated_tokenizers import ByteBPEProcessor

from .compat import has_huggingface_hub, huggingface_hub


@pytest.fixture(scope="module")
def test_dir(request):
    return Path(request.fspath).parent


@pytest.fixture
def text_troonrede(test_dir):
    with open(test_dir / "troonrede.txt", encoding="utf-8") as f:
        return [line.strip() for line in f if line.strip()]


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


@pytest.fixture
def robbert_processor():
    vocab_path = huggingface_hub.hf_hub_download(
        "pdelobelle/robbert-v2-dutch-base", "vocab.json"
    )
    merges_path = huggingface_hub.hf_hub_download(
        "pdelobelle/robbert-v2-dutch-base", "merges.txt"
    )
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
    with pytest.raises(ValueError, match=r"Vocabulary does not contain byte"):
        bbpe.encode_as_pieces("they'll visit Köln")


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


def encode_sample_text(processor, paragraphs):
    for p in paragraphs:
        processor.encode(p)


@pytest.mark.bench
@pytest.mark.skipif(not has_huggingface_hub, reason="requires huggingface_hub")
def test_speed(benchmark, robbert_processor, text_troonrede):
    benchmark(encode_sample_text, robbert_processor, text_troonrede)
