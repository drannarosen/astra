# Installation

ASTRA assumes that contributors are working with a modern Julia installation. The Julia project currently recommends `juliaup` for installing and managing the latest stable Julia release.

## Install Julia

Follow the official instructions:

- https://julialang.org/downloads/

For macOS and Linux, the official `juliaup` installer is:

```bash
curl -fsSL https://install.julialang.org | sh
```

Windows users should follow the official Juliaup instructions on the Julia downloads page.

Verify the installation with:

```bash
julia --version
```

## Bootstrap ASTRA

From the repository root:

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.precompile()'
julia --project=. -e 'using ASTRA'
```

If `using ASTRA` runs without error, the bootstrap succeeded.

## Why ASTRA uses plain cgs `Float64` values

If you are coming from Python/JAX, one design choice may stand out immediately: ASTRA does not use runtime unit types in the initial solver path. This is an intentional architectural choice, not a statement against units in general. The hot kernels should look like ordinary scientific arrays and scalars, solver and performance behavior should remain easy to reason about, and unit meaning should stay explicit through names, docstrings, and tests.

That tradeoff keeps the bootstrap solver path lightweight while keeping unit meaning explicit.
