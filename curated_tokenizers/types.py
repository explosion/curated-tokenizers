from pathlib import Path
from typing import IO, Union


# TODO: str is for compatibility, remove on the next semver version.
FileLike = Union[IO, Path, str]
