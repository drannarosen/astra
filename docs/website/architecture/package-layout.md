# Package Layout

The package is deliberately a **single root Julia package** rather than a multi-package workspace.

## Why one package first

At bootstrap, one coherent package is easier to reason about than a forest of subpackages. Julia already gives us strong namespacing through modules and file boundaries, so we can keep the public surface small without multiplying package-level complexity.

## Layout map

- `src/ASTRA.jl`: top-level module and public exports
- `src/constants.jl`, `src/config.jl`, `src/types.jl`, `src/grid.jl`, `src/state.jl`: foundation layer
- `src/microphysics/`: toy physics interfaces
- `src/residuals.jl`, `src/jacobians.jl`, `src/solvers/`: numerical layer
- `src/formulations/`: method family surface
- `src/evolution/`: explicitly deferred time-dependent layer

The package layout is designed to teach ownership before it teaches cleverness.
