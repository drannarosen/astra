# Data Model

ASTRA's current implementation is centered on small immutable structs:

- `Composition`
- `StellarParameters`
- `GridConfig`
- `SolverConfig`
- `StellarGrid`
- `StructureState`
- `CompositionState`
- `EvolutionState`
- `StellarModel`
- `MicrophysicsBundle`
- `StructureProblem`
- `StructureDiagnostics`

That list describes the **current code**, not the final ownership model.

## Transitional implementation versus canonical architecture

The bootstrap package now exposes the explicit ownership split directly in code.

An internal `StellarState` helper still exists only as transitional legacy scaffolding. The canonical split is:

- `StructureState`
- `CompositionState`
- `EvolutionState`

## Why immutable structs

If you are coming from Python, this is one of the most important Julia design moves to notice. Immutable structs make ownership clearer and reduce accidental side effects. We can still mutate arrays inside a struct later for hot-path performance, but the high-level object identity remains stable and readable.

## Why parametric bundles matter

`MicrophysicsBundle{E,O,N,C}` is a Julia-specific design win. It lets the package store concrete callable types for EOS, opacity, nuclear, and convection closures without paying the cost of abstractly typed containers.

## The important ownership lesson

The point of the data model is not just to hold numbers. It is to make it obvious which numbers are:

- persistent model state,
- solve-owned unknowns,
- evolution-owned metadata,
- or derived closures.

That ownership clarity is more important to ASTRA than shaving a few lines off the type definitions.
