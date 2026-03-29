# Installation

ASTRA assumes a modern Julia installation. The Julia project currently recommends `juliaup` for installing and managing the latest stable Julia release.

## Install Julia

Follow the official instructions:

- https://julialang.org/downloads/

On a machine with `juliaup` available, verify the install with:

```bash
julia --version
```

## Bootstrap ASTRA

From the repository root:

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'
julia --project=. -e 'using ASTRA'
```

## Why ASTRA uses plain cgs `Float64` values

If you are coming from Python/JAX, one design choice may stand out immediately: ASTRA does not use runtime unit types in the initial solver path. The reason is architectural, not anti-safety. We want the hot numerical kernels to look like ordinary scientific arrays and scalars, while keeping unit meaning explicit through names, docstrings, and tests.

That tradeoff keeps the bootstrap lightweight and makes later performance work easier to reason about.
