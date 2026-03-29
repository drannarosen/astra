# ASTRA

**ASTRA** stands for **Adaptive STellar Research Architecture**.

ASTRA is a modern Julia framework for stellar structure and evolution with a deliberately narrow initial scope: single-star, 1D, spherically symmetric, hydrostatic, forward-solver-first stellar modeling. It is being built as a clean research laboratory for classical structure methods, validation workflows, and later method comparisons such as Entropy-DAE.

## Why ASTRA exists

ASTRA has a different job than Stellax.

- **Stellax** is the flagship differentiable stellar modeling framework, where gradients and inference-native workflows are central.
- **ASTRA** is the Julia-first forward-model laboratory, where clarity, validation readiness, solver architecture, and controlled method comparison come first.

ASTRA is not a MESA clone, not a feature warehouse, and not a rushed attempt to implement every piece of stellar evolution at once.

## Current bootstrap status

This repository bootstrap covers Milestone 0 and the beginning of Milestone 1:

- a root Julia package scaffold,
- a pedagogical MystMD documentation site,
- a modular `src/` tree,
- tests and examples for the scaffolded interfaces,
- planning and contributor guidance,
- toy physics and solver pathways that are intentionally honest about being placeholders.

The bootstrap does **not** claim to provide a research-grade stellar solver yet.

## Repository layout

```text
src/        Julia package source
test/       Unit and scaffold checks
docs/       MystMD website and planning artifacts
examples/   Small runnable examples
benchmark/  Benchmark placeholders and future performance notes
scripts/    Local developer scripts
```

## Getting started

Julia is not vendored into the repository. The recommended installation route is `juliaup`, which the Julia project currently recommends for installing the latest stable Julia release:

https://julialang.org/downloads/

Once Julia is installed:

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'
julia --project=. -e 'using ASTRA'
julia --project=. -e 'using Pkg; Pkg.test()'
julia --project=. scripts/run_examples.jl
```

## Docs

ASTRA’s documentation is a MystMD handbook rather than an auto-generated API dump. To preview it locally:

```bash
cd docs/website
myst start
```

To build the static site:

```bash
cd docs/website
myst build --site --html --strict
```

## Design rules

- Correctness before performance.
- Validation before feature growth.
- Small public API, rich internal modularity.
- Classical baseline first.
- Entropy-DAE belongs in ASTRA later, but does not define ASTRA’s whole identity.
- cgs `Float64` values in the solver path, with units enforced by names, docs, and tests.

## License

BSD-3-Clause. See [LICENSE](LICENSE).
