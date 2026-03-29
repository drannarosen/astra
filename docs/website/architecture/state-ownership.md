# State Ownership

ASTRA's first serious classical lane should treat the stellar model as a bundle of explicitly owned sub-states rather than one undifferentiated state vector.

## Canonical conceptual split

The approved conceptual model is:

- `StructureState`
- `CompositionState`
- `EvolutionState`

The public model contract now uses `StellarModel` to bundle those three blocks. The old bootstrap `StellarState` remains only as an internal transitional scaffold and should not be treated as the public ownership model.

## StructureState

`StructureState` is the nonlinear solve-owned block for the classical baseline.

Approved centering:

- face-centered `ln_r_face`
- face-centered `luminosity_face`
- cell-centered `ln_T_cell`
- cell-centered `ln_rho_cell`

This is a MESA-like staggered arrangement and is physically natural for a mass-coordinate 1D stellar solver.

## CompositionState

For the first solar evolution lane, `CompositionState` should store explicit cell-centered bulk composition arrays:

- `X_cell`
- `Y_cell`
- `Z_cell`

These arrays are:

- persistent physical state,
- used by EOS, opacity, and nuclear closures,
- frozen during the first hydrostatic structure solves,
- and later updated by the evolution layer.

### Invariants

- all fractions are non-negative,
- `X + Y + Z = 1` in each cell up to declared tolerance.

## Reserved future path

The bulk-composition layer is intentionally not the endpoint.

ASTRA should reserve a clean future path for:

- isotope-vector composition states,
- transport fluxes defined at faces,
- reconstructed interface abundances,
- and richer burning / mixing operators.

That future path should preserve one central ownership rule:

> Cell-centered composition is the canonical persisted state. Face composition is an operator-owned transport quantity.

This is the physically conservative choice and is well aligned with MESA's use of cell-centered abundance variables plus face-based mixing flows when transport is active. See [MESA developer tour](https://docs.mesastar.org/en/release-r22.05.1/developing/tour.html).

## EvolutionState

`EvolutionState` should own:

- age,
- timestep size,
- previous accepted timestep,
- accepted and rejected step counters,
- and later energy-bookkeeping metadata.

One of the main reasons to keep this separate is that gravothermal terms are timestep-aware and should not be treated as free-floating diagnostics.
