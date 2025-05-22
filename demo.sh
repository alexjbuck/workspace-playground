#!/bin/bash

set -v

# "Reset the environment"
rm -rf .venv

# "Install all packages into the virtual environment (and all of their dependencies)"
# "Both will succeed because _all_ dependencies are installed into the same 1 virtual environment."
uv sync --all-packages

uv run mypy app

uv run mypy lib

# "Install just the root package into the virtual environment"
# "Both will fail because they uses dependencies that aren't in the root package"
uv sync

uv run mypy app

uv run mypy lib


# "Install the `app` package into the virtual environment"
# "`lib` will succeed because it uses a leaked dependency from `app`"
uv sync --package app

uv run mypy app

uv run mypy lib

# "Install the `lib` package into the virtual environment."
# "`app` will succeed because it uses a leaked dependency from `lib`"
uv sync --package lib

uv run mypy app

uv run mypy lib


# "Reset the environment and run mypy from the packages environment"
# "The paths are still relative to the root"
# "Running mypy in the app package will fail, but after running the lib package, running mypy in the app package will succeed"
uv sync

uv run --package app mypy app

uv run --package lib mypy lib

uv run --package app mypy app

# "Reset the environment and run mypy from the packages environment"
# "The paths are still relative to the root"
# "We reverse the order this time, and run mypy in the lib package first"
# "Running mypy in the lib package will fail, but after running the app package, running mypy in the lib package will succeed"
uv sync

uv run --package lib mypy lib

uv run --package app mypy app

uv run --package lib mypy lib
