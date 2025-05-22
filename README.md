# uv workspaces are leaky

## repository organization
```
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
```

Notable setup:

- package `app` has 1 dependency in its pyproject.toml file: `structlog` but it
  imports `matplotlib`
- package `lib` has 1 dependency in its pyproject.toml file: `matplotlib` but
  it imports `structlog`
- Neither package has `mypy` in its dev dependencies (to begin with)

This setup is somewhat contrived, and at first seems obviously incorrect, but
you'll see that depending on the order of operations this workspace will
sometimes lint successfully and othertimes it may fail.

**THIS IS REALLY BAD** and this is the key takeaway.

## How to get started

First just take a peak through the workspace layout.

Next, run `./demo.sh`. It will run a bunch of commands and print stuff to the
terminal for reading.

Observe the weird behavior.

## Why does this happen?

This happens because of the semantic difference between `uv sync` and `uv run`. 

`uv sync` by default will _exactly_ make the environment match the specified
`pyproject.toml` file. This declarative nature is part of what makes `uv` so
amazing to work with, and improves the reproducibility of a package.

`uv run` by default will _inexactly_ make the environment match the specified
`pyproject.toml` file. This violates the declarative nature of `uv`. **This is
generally only a detectable difference in a workspace environment.**

In a non-workspace environment there is only one `pyproject.toml` file, so the
only way for the local environment to get out of sync with the relevant
`pyproject.toml` file is for the user to have manually manipulated the
environment via something like `uv pip install ...`. Any sequence of `uv sync`
or `uv run` always is in reference to the singular `pyproject.toml` file so it
can't get out of sync with itself. 

This all goes out the window in a workspace environment. Now you have multiple
pyproject.toml files and some combination of them is responsible for the
current state of the virtual environment depending on how you `sync`'d the
environment. Did you `uv sync --all-packages` or did you `uv sync --package
app`? Are you sure? Does your IDE tooling know?

Okay, that's just a complication but we can work through that, surely it won't
let us do dangerous things?

Wrong again.

Lets say you have a workspace with two packages, an app and a backend api.
Start by  running `uv sync --all-packages`. Now your virtual environment
represents the union of all the dependencies of all your packages. We know that
all our packages can be installed together. Woo! However, now your IDE will
also let you import a dependency that was specified in a different package.
Working on a new feature in the `super-cool-ai-app` package? Need to make use
of a `polars` DataFrame? Oh look, its already in the virtual environment and
your IDE auto-completed it for you! Thats' great!

:skull:

What you forgot is that `polars` is only available because its a dependency of
`super-cool-backend-api` but it was ***leaked*** to you in `super-cool-ai-app`
because there's only one virtual environment. There's only one virtual
environment because you chose to use a workspace.

But I need to make sure that my app and api can be installed together!

Okay? Make your root package that doesn't do anything depend on both of them.
If they can be resolved together there, then they're compatible.

```
.
└── monorepo root/
    ├── pyproject.toml
    ├── .venv
    └── packages/
        ├── super-cool-ai-app/
        │   ├── pyproject.toml
        │   └── .venv
        └── super-cool-backend-api/
            ├── pyproject.toml
            └── .venv
```
Have root depend on both the app and api via path dependencies. If it can
resolve, then they are compatible.

No leaky workspaces required
