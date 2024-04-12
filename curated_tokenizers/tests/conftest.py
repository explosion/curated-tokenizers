import pytest


def pytest_addoption(parser):
    try:
        parser.addoption("--bench", action="store_true", help="include benchmarks")
    # Options are already added, e.g. if conftest is copied in a build pipeline
    # and runs twice
    except ValueError:
        pass


def pytest_configure(config):
    config.addinivalue_line("markers", "bench: include benchmark tests")


def pytest_runtest_setup(item):
    def getopt(opt):
        # When using 'pytest --pyargs spacy' to test an installed copy of
        # spacy, pytest skips running our pytest_addoption() hook. Later, when
        # we call getoption(), pytest raises an error, because it doesn't
        # recognize the option we're asking about. To avoid this, we need to
        # pass a default value. We default to False, i.e., we act like all the
        # options weren't given.
        return item.config.getoption(f"--{opt}", False)

    # Integration of boolean flags
    for opt in ["bench"]:
        if opt in item.keywords and not getopt(opt.replace("_", "-")):
            pytest.skip(f"need --{opt.replace('_', '-')} option to run")
