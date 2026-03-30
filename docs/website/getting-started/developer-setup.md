# Developer Setup

This page is written for contributors who may be new to Julia. The goal is simple: get the code running, run the main checks, and understand the basic development workflow ASTRA expects.

## Local workflow

From the repository root, run:

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'
julia --project=. -e 'using Pkg; Pkg.test()'
julia --project=. scripts/run_examples.jl
```

This is the normal local workflow: set up the environment, run the tests, then run the examples.

These commands do different jobs:

- `--project=.` tells Julia to use the environment stored in this repository.
- `Pkg.instantiate()` installs the packages listed for this project.
- `Pkg.precompile()` compiles those packages ahead of time so later runs start faster.
- `Pkg.test()` runs the test suite.
- `scripts/run_examples.jl` runs the example scripts that exercise the current public workflow.

### Julia environments

In Julia, an **environment** is the set of packages and versions a project uses. ASTRA keeps its own environment in the repository so every contributor can work against the same package setup. That is why the commands above use `--project=.`: it tells Julia to use ASTRA's environment, not whatever happens to be installed globally on your machine.

## Docs workflow

ASTRA's documentation uses **MyST**, a documentation system for writing pages in Markdown and building them into a site.

```bash
cd docs/website
myst start
```

`myst start` launches a local preview website on your machine so you can view the docs in a browser while you edit them.

For a strict build:

```bash
cd docs/website
myst build --site --html --strict
```

The strict build is useful because it catches documentation problems early, including broken references and formatting mistakes that a casual preview might miss.

## Julia-specific orientation

If you are new to Julia, a few ideas will make the ASTRA codebase much easier to read.

In Julia, a **package** is a named project. In ASTRA, that project name is `ASTRA`, and the package also carries the environment used by the repository. A **namespace** is the named space that holds code so functions and types live under that project name. An **environment** is the package setup discussed above: the dependency list and versions used by this repository.

`src/ASTRA.jl` is the module entrypoint. In practice, that means it is the main file that defines the `ASTRA` module and then loads the rest of the source files in the order the package needs them.

**Multiple dispatch** means Julia chooses which method to run based on the types of the inputs. In ASTRA, that helps keep formulation logic and microphysics interfaces explicit without pushing everything through one large conditional block.

**Parametric structs** are typed data structures where Julia knows in advance what kinds of values they contain. **Generic containers** are looser containers that can mix many kinds of values. ASTRA prefers parametric structs for the microphysics bundle and other hot-path data so the solver behaves more like ordinary scientific code with predictable arrays and scalars, and stays easier to reason about for both performance and correctness.
