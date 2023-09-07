from pathlib import Path
from typing import IO

from curated_tokenizers.types import FileLike


def _check_is_io_like(f: IO):
    if not (hasattr(f, "read") and hasattr(f, "write")):
        raise ValueError("Object is not IO-like")


class _wrap_file_object:
    def __init__(self, f):
        _check_is_io_like(f)
        self.f = f

    def __enter__(self):
        return self.f

    def __exit__(self, *args):
        pass


def open_file_like(f: FileLike, mode="r", encoding=None):
    """
    Open a file-like object. The result can always be used in a
    context manager.

    :param f:
        The object to open. Either a file opject or a local path.
    :param mode:
        The opening mode, ignored when the ``f`` is a file object.
    :param encoding:
        The encoding to use, ignored when the ``f`` is a file object
        or the mode is binary.

    """
    if isinstance(f, Path) or isinstance(f, str):
        return open(f, mode=mode, encoding=encoding)
    else:
        return _wrap_file_object(f)
