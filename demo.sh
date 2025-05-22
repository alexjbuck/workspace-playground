#!/bin/bash

set -v

# "Reset the environment"
rm -rf .venv

# Ok, this is a _somewhat_ contrived example but it shows how you can leak
# state about the virtual environment outside of a package if using workspaces.

# First lets show you the contents of our application and our library
cat app/src/app/main.py

cat lib/src/lib/lib.py

# You can see that `main.py` imports `matplotlib`, but that library is not
# included in its pyproject.toml.

# Also, `lib.py` imports `structlog` but that library is not included in _its_
# pyproject.toml

# This repo is configured with `app` depending on `structlog` and `lib` depending on `matplotlib`
# This is a "cross" in the dependencies and I hope to illustrate how this can be problematic.

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

# You can't leverage installing dev tools/linters/checkers in only the root
# package and use them in workspace packages. The --package flag means "run as
# if you were that packages virtual environment as specified by the pyproject.toml"
uv sync

uv run --package app mypy app

uv run --package lib mypy lib

# Ok, lets install mypy as a dev-dependency into both packages then.

uv add --package app --dev mypy

cat app/pyproject.toml

uv add --package lib --dev mypy

cat lib/pyproject.toml

# "Reset the environment and run mypy from the packages environment"
# "Now, the order of running things matters!"
# "Running mypy in the app package will fail, but after running the lib package, running mypy in the app package will succeed"

uv sync

uv run --package app mypy app

uv run --package lib mypy lib

uv run --package app mypy app

# "Reset the environment and run mypy from the packages environment"
# "We reverse the order this time, and run mypy in the lib package first"
# "Running mypy in the lib package will fail, but after running the app package, running mypy in the lib package will succeed"
uv sync

uv run --package lib mypy lib

uv run --package app mypy app

uv run --package lib mypy lib

# Clean up
uv remove --package app --dev mypy

uv remove --package lib --dev mypy

# Okay, now, lets remember how we configure our tools in Cursor extensions to operate. 
# Tools like `mypy` need reference to a `mypy`/`dmypy` executable. That only lives in one place,
# inside the virtual environment.
#
# The state of the virtual environment depends on how you ran `uv sync` now. 
#
# Lets say you ran `uv run --package app ruff --fix`, well now the venv matches that of `app`.
# Suddenly mypy will start complaining about undefined imports in the `lib` package!
#
# Ok, fine, we will only use tools from the workspace root then and never run things from within 
# a package context, and we'll always use `uv sync --all-packages`.
#
# Not good either.
#
# Now if you add a dependency to `lib` its suddenly "available" to `app` even though its not specified
# in app's pyproject.toml.
#
# You can test this just by seeing the linter results after `uv sync` vs `uv sync --all-packages`
#
# Heck, if you have a package that doesn't have `mypy` installed and you `sync` that package, now you get
# mypy errors that `dmypy` can't be found in the environment, which it isn't, because you removed it
# by running `uv sync --package pkg-without-mypy`.

