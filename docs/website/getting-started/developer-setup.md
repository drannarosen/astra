# Developer Setup

ASTRA is meant to be readable by a new graduate student contributor, including one who is strong in Python or C++ but new to Julia.

## Local workflow

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'
julia --project=. -e 'using Pkg; Pkg.test()'
julia --project=. scripts/run_examples.jl
```

## Docs workflow

```bash
cd docs/website
myst start
```

For a strict build:

```bash
cd docs/website
myst build --site --html --strict
```

## Julia-specific orientation

- A Julia package is both a namespace and an environment.
- `src/ASTRA.jl` defines the top-level module and `include`s the source files in dependency order.
- Multiple dispatch is used for formulation selection and microphysics callables.
- Parametric structs, not abstract containers, carry the microphysics bundle so the hot path stays type-stable.
