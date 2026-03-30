# Reading the Codebase

If you are new to Julia, the most important reading habit is to follow the module boundaries rather than chasing filenames randomly.

That advice is really about modular code. A good scientific codebase should let you read one layer at a time: what the data model is, what the local physics does, what equations are assembled, and how the solver acts on them.

## Good reading order

1. `src/ASTRA.jl`
2. `src/foundation/config.jl` and `src/foundation/types.jl`
3. `src/foundation/grid.jl` and `src/foundation/state.jl`
4. `docs/website/architecture/contracts-overview.md`
5. `src/microphysics/`
6. `src/numerics/` and `src/solvers/`
7. `src/formulations/`

That order mirrors ownership: data first, then closures, then numerics, then method dispatch. It also mirrors a good way to structure modular code in your own work: read and design from stable foundations outward rather than jumping straight into the solver loop.

When you read `src/foundation/types.jl` and `src/foundation/state.jl`, look first for the explicit ownership split:

- `StellarModel`
- `StructureState`
- `CompositionState`
- `EvolutionState`

That split is the canonical contract for the bootstrap classical lane. The old flat `StellarState` scaffold still exists only as an internal transitional artifact.

One practical lesson is worth keeping in mind as you read: when a directory starts to carry a real conceptual layer, it should usually become a directory on purpose rather than leaving its files as loose peers in `src/`. ASTRA's `foundation/` and `numerics/` layers are there to make that architectural story visible.
