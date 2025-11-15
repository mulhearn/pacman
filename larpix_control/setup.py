from setuptools import setup, find_packages

# read the README.txt for long description
with open("README.txt", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setup(
    name="larpix_control",
    version="0.1.0",
    description="Control software for PACMAN and LArPix ASICs",
    long_description=long_description,
    long_description_content_type="text/plain",
    author="The LArPix Project",
    packages=find_packages(),
    install_requires=[
        # list external dependencies here, e.g. "numpy>=1.25"
    ],
    python_requires=">=3.9",
)
