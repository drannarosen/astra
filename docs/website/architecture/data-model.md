# Data Model

ASTRA's bootstrap data model is centered on small immutable structs:

- `Composition`
- `StellarParameters`
- `GridConfig`
- `SolverConfig`
- `StellarGrid`
- `StellarState`
- `MicrophysicsBundle`
- `StructureProblem`
- `StructureDiagnostics`

## Why immutable structs

If you are coming from Python, this is one of the most important Julia design moves to notice. Immutable structs make ownership clearer and reduce accidental side effects. We can still mutate arrays inside a struct later for hot-path performance, but the high-level object identity remains stable and readable.

## Why parametric bundles matter

`MicrophysicsBundle{E,O,N,C}` is a Julia-specific design win. It lets the package store concrete callable types for EOS, opacity, nuclear, and convection closures without paying the cost of abstractly typed containers.
