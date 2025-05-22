# An illustration of leaky boundaries between workspace packages

## Repository organization
.
├── app
│   ├── pyproject.toml
│   ├── README.md
│   └── src
│       └── app
│           ├── __init__.py
│           └── main.py
├── demo.sh
├── lib
│   ├── pyproject.toml
│   ├── README.md
│   └── src
│       └── lib
│           ├── __init__.py
│           └── lib.py
├── main.py
├── pyproject.toml
├── README.md
└── uv.lock

Notable setup:

- package `app` has 1 dependency in its pyproject.toml file: `structlog`
- package `lib` has 1 dependency in its pyproject.toml file: `matplotlib`
- Neither package has `mypy` in its dev dependencies (to begin with)

This setup is somewhat contrived, and at first seems obviously incorrect, but you'll see
that depending on the order of operations this workspace will sometimes lint successfully
and othertimes it may fail.

**THIS IS REALLY BAD** and this is the key takeaway.

## How to get started

First just take a peak through the workspace layout.

Next, run `./demo.sh`. It will run a bunch of commands and print stuff to the terminal for reading.

Observe the weird behavior.
