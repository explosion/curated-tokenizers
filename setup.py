from setuptools import setup
from setuptools_rust import Binding, RustExtension

setup(
    name="cutlery",
    rust_extensions=[RustExtension("cutlery.cutlery", binding=Binding.PyO3)],
    packages=["cutlery"],
    zip_safe=False,
)
