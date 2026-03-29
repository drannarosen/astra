# Reading the Codebase

If you are new to Julia, the most important reading habit is to follow the module boundaries rather than chasing filenames randomly.

## Good reading order

1. `src/ASTRA.jl`
2. `src/config.jl` and `src/types.jl`
3. `src/grid.jl` and `src/state.jl`
4. `src/microphysics/`
5. `src/residuals.jl`, `src/jacobians.jl`, and `src/solvers/`
6. `src/formulations/`

That order mirrors ownership: data first, then closures, then numerics, then method dispatch.
