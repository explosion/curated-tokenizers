#!/usr/bin/env python
import sys
import distutils.util
from distutils.command.build_ext import build_ext
from setuptools import Extension, setup, find_packages
from pathlib import Path
from Cython.Build import cythonize
from Cython.Compiler import Options


# Preserve `__doc__` on functions and classes
# http://docs.cython.org/en/latest/src/userguide/source_files_and_compilation.html#compiler-options
Options.docstrings = True


def prefix_path(prefix, files):
    return list(map(lambda f: f"{prefix}/{f}", files))


ABSL_SRC = prefix_path(
    "sentencepiece/third_party/absl", ["flags/flag.cc", "strings/string_view.cc"]
)

PROTOBUF_LIGHT_SRC = prefix_path(
    "sentencepiece/third_party/protobuf-lite",
    [
        "arena.cc",
        "arenastring.cc",
        "bytestream.cc",
        "coded_stream.cc",
        "common.cc",
        "extension_set.cc",
        "generated_enum_util.cc",
        "generated_message_table_driven_lite.cc",
        "generated_message_util.cc",
        "implicit_weak_message.cc",
        "int128.cc",
        "io_win32.cc",
        "message_lite.cc",
        "parse_context.cc",
        "repeated_field.cc",
        "status.cc",
        "statusor.cc",
        "stringpiece.cc",
        "stringprintf.cc",
        "structurally_valid.cc",
        "strutil.cc",
        "time.cc",
        "wire_format_lite.cc",
        "zero_copy_stream.cc",
        "zero_copy_stream_impl.cc",
        "zero_copy_stream_impl_lite.cc",
    ],
)

SENTENCEPIECE_PROTOBUF_SRC = prefix_path(
    "sentencepiece/src/builtin_pb", ["sentencepiece.pb.cc", "sentencepiece_model.pb.cc"]
)

SENTENCEPIECE_SRC = prefix_path(
    "sentencepiece/src",
    [
        "bpe_model.cc",
        "char_model.cc",
        "error.cc",
        "filesystem.cc",
        "model_factory.cc",
        "model_interface.cc",
        "normalizer.cc",
        "sentencepiece_processor.cc",
        "unigram_model.cc",
        "util.cc",
        "word_model.cc",
    ],
)

PACKAGES = find_packages()
MOD_NAMES = [
    "cutlery.sp",
]
COMPILE_OPTIONS = {
    "msvc": [
        "/Ox",
        "/EHsc",
        "/D_USE_INTERNAL_STRING_VIEW",
        "/DHAVE_PTHREAD",
        "/wd4018",
        "/wd4514",
    ],
    "other": [
        "--std=c++14",
        "-Wno-sign-compare" "-Wno-strict-prototypes",
        "-Wno-unused-function",
        "-D_USE_INTERNAL_STRING_VIEW",
        "-pthread",
        "-DHAVE_PTHREAD=1",
    ],
}
COMPILER_DIRECTIVES = {
    "language_level": -3,
    "embedsignature": True,
    "annotation_typing": False,
}
LINK_OPTIONS = {"msvc": [], "other": []}


def is_new_osx():
    """Check whether we're on OSX >= 10.10"""
    name = distutils.util.get_platform()
    if sys.platform != "darwin":
        return False
    elif name.startswith("macosx-10"):
        minor_version = int(name.split("-")[1].split(".")[1])
        if minor_version >= 7:
            return True
        else:
            return False
    else:
        return False


if is_new_osx():
    # On Mac, use libc++ because Apple deprecated use of libstdc
    COMPILE_OPTIONS["other"].append("-stdlib=libc++")
    LINK_OPTIONS["other"].append("-lc++")
    # g++ (used by unix compiler on mac) links to libstdc++ as a default lib.
    # See: https://stackoverflow.com/questions/1653047/avoid-linking-to-libstdc
    LINK_OPTIONS["other"].append("-nodefaultlibs")


# By subclassing build_extensions we have the actual compiler that will be used
# which is really known only after finalize_options
# http://stackoverflow.com/questions/724664/python-distutils-how-to-get-a-compiler-that-is-going-to-be-used
class build_ext_options:
    def build_options(self):
        if hasattr(self.compiler, "initialize"):
            self.compiler.initialize()
        self.compiler.platform = sys.platform[:6]
        for e in self.extensions:
            e.extra_compile_args = COMPILE_OPTIONS.get(
                self.compiler.compiler_type, COMPILE_OPTIONS["other"]
            )
            e.extra_link_args = LINK_OPTIONS.get(
                self.compiler.compiler_type, LINK_OPTIONS["other"]
            )


class build_ext_subclass(build_ext, build_ext_options):
    def build_extensions(self):
        build_ext_options.build_options(self)
        build_ext.build_extensions(self)


def clean(path):
    for path in path.glob("**/*"):
        if path.is_file() and path.suffix in (".so", ".cpp"):
            print(f"Deleting {path.name}")
            path.unlink()


def setup_package():
    root = Path(__file__).parent

    if len(sys.argv) > 1 and sys.argv[1] == "clean":
        return clean(root / "cutlery")

    ext_modules = [
        Extension(
            "cutlery._spp",
            ["cutlery/_spp.pyx"]
            + ABSL_SRC
            + PROTOBUF_LIGHT_SRC
            + SENTENCEPIECE_SRC
            + SENTENCEPIECE_PROTOBUF_SRC,
            include_dirs=[
                "cutlery",
                "sentencepiece",
                "sentencepiece/src",
                "sentencepiece/src/builtin_pb",
                "sentencepiece/third_party/protobuf-lite",
            ],
            language="c++",
        ),
        Extension(
            "cutlery._wordpiece",
            ["cutlery/_wordpiece.pyx", "cutlery/wordpiece.cc"],
            language="c++",
        ),
        Extension(
            "cutlery._bbpe",
            ["cutlery/_bbpe.pyx", "cutlery/merges.cc"],
            include_dirs=["cutlery"],
            language="c++",
        ),
    ]
    print("Cythonizing sources")
    ext_modules = cythonize(
        ext_modules, compiler_directives=COMPILER_DIRECTIVES, language_level=2
    )
    setup(
        name="cutlery",
        packages=PACKAGES,
        ext_modules=ext_modules,
        cmdclass={"build_ext": build_ext_subclass},
        package_data={"": ["*.pyx", "*.pxd", "*.pxi", "*.cu", "*.hh"]},
    )


if __name__ == "__main__":
    setup_package()
