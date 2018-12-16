"""Setuptools based setup module."""

# Always prefer setuptools over distutils
from setuptools import setup, find_packages
from os import path

here = path.abspath(path.dirname(__file__))

# Get the long description from the README file
with open(path.join(here, 'README.md'), encoding='utf-8') as f:
    long_description = f.read()

setup(
    name='magicassistantutils',
    version='1.0.0',
    description='Magic Assistant helpers',
    long_description=long_description,
    long_description_content_type='text/markdown',
    url='https://github.com/troyready/magicassistantutils',
    author='Troy Ready',
    author_email='troy+dropafterplus@troyready.com',
    python_requires='>3.5.2',
    packages=find_packages(exclude=['contrib', 'docs', 'tests']),
    install_requires=['mtgsdk', 'PyYAML'],
    extras_require={
        'test': ['nose', 'flake8', 'pep8-naming', 'flake8-docstrings', 'mypy'],
    },
    package_data={
        'magicassistantutils': ['mapping_files/*.yml'],
    },
    test_suite='tests'
)
