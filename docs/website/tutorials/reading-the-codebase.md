# Reading the Codebase

If you are new to Julia, the most important reading habit is to follow the module boundaries rather than chasing filenames randomly.

## Good reading order

1. `src/ASTRA.jl`
2. `src/config.jl` and `src/types.jl`
3. `src/grid.jl` and `src/state.jl`
4. `docs/website/architecture/contracts-overview.md`
5. `src/microphysics/`
6. `src/residuals.jl`, `src/jacobians.jl`, and `src/solvers/`
7. `src/formulations/`

That order mirrors ownership: data first, then closures, then numerics, then method dispatch.

When you read `src/types.jl` and `src/state.jl`, look first for the explicit ownership split:

- `StellarModel`
- `StructureState`
- `CompositionState`
- `EvolutionState`

That split is the canonical contract for the bootstrap classical lane. The old flat `StellarState` scaffold still exists only as an internal transitional artifact.
