# State Ownership

ASTRA's first serious classical lane treats the stellar model as a bundle of explicitly owned sub-states rather than one giant undifferentiated vector. That is not just a data-layout preference. It is how the code keeps clear which quantities are long-lived model state, which quantities the current solver may update, and which quantities are only derived when needed.

## Canonical conceptual split

The public model contract is:

- `StructureState`
- `CompositionState`
- `EvolutionState`

Those three blocks are bundled by `StellarModel`. The older bootstrap `StellarState` still exists as an internal transitional scaffold, but it is not the public ownership model ASTRA is teaching contributors to use. It may still appear in transitional code paths, but contributors should not treat it as a second valid conceptual model.

## StructureState

`StructureState` is the current **solve-owned** block. In plain language, it is the part of the model the classical nonlinear solve is allowed to change directly.

Its approved centering is:

- face-centered `ln_r_face`,
- face-centered `luminosity_face`,
- cell-centered `ln_T_cell`,
- cell-centered `ln_rho_cell`.

This staggering matches the physical roles of the variables in a mass-coordinate stellar solver. Radius and luminosity naturally live on shell faces, while temperature and density naturally describe cell interiors.

When you read the code, the key ownership question is simple: what gets packed into the Newton vector? In the current contract, only `model.structure` crosses that boundary.

**Current classical solve boundary:** only `StructureState` is packed into the Newton unknown vector.

### StructureState invariants

- `ln_r_face` corresponds to a strictly increasing physical radius field after exponentiation.
- `ln_T_cell` and `ln_rho_cell` correspond to positive physical temperature and density.
- Centering and array lengths remain consistent with the mesh contract.

## CompositionState

`CompositionState` stores the explicit bulk composition carried by the model:

- `X_cell`,
- `Y_cell`,
- `Z_cell`.

Physically, these arrays describe what the stellar material is made of in each cell. They are persistent state even when the current structure solve keeps them fixed. That is an important ASTRA habit: the structure equations depend on composition, but that dependence does not automatically make composition solve-owned.

The most important invariant is simple: all fractions stay non-negative and `X + Y + Z = 1` in each cell up to the declared tolerance.

### CompositionState invariants

- All mass fractions are non-negative.
- `X + Y + Z = 1` to the declared tolerance in every cell.
- Composition is persistent state even when the current structure solve keeps it fixed.

## EvolutionState

`EvolutionState` owns timestep-aware metadata such as age, timestep size, previous accepted timestep, accepted-step counters, rejected-step counters, and later energy-bookkeeping data.

Physically, this is the part of the model that belongs to time evolution rather than to one fixed structure solve.

Current responsibilities are straightforward:

- age,
- current timestep size,
- previous accepted timestep,
- accepted-step counters,
- rejected-step counters.

Reserved near-term responsibilities include gravothermal bookkeeping, acceptance metrics, and controller memory. Keeping this state separate matters because later timestep-aware logic should have a real home instead of drifting into ad hoc diagnostics.

### EvolutionState invariants

- Age is non-decreasing across accepted steps.
- Timestep sizes are positive.
- Step counters remain internally consistent with accepted and rejected updates.

## Derived, not persisted

Some quantities are essential to the solve without being canonical stored state. Pressure, opacity, nuclear energy generation, transport gradients or coefficients, and face-reconstructed composition quantities all fall into this category.

That distinction matters because essential does not mean persisted. In ASTRA's architecture, these quantities are derived from the canonical state by closures or operators when needed. They should not quietly become a second shadow state model.

## Reserved future path

The bulk-composition layer is intentionally not the endpoint. ASTRA should later grow into richer composition representations, including isotope vectors, transport fluxes, reconstructed interface abundances, and more realistic burning or mixing operators.

The ownership rule should stay the same even as the physics grows: cell-centered composition is the canonical persisted state, while any face-based composition quantity belongs to a transport or reconstruction operator rather than to the core stored model.

## Internal QA checklist

### Contract clarity

- [x] The page states the public `StructureState` / `CompositionState` / `EvolutionState` split.
- [x] The page explains that only `model.structure` is currently solve-owned.
- [x] The page explains why composition remains persistent state even when frozen during the first structure solves.
- [x] The page gives evolution-aware quantities a dedicated owner instead of treating them as loose diagnostics.

### Invariants

- [x] Structure invariants are stated explicitly.
- [x] Composition invariants are stated explicitly.
- [x] Evolution invariants are stated explicitly.

### Legacy containment and future growth

- [x] Transitional `StellarState` is marked as an internal transitional scaffold, not an alternate canonical model.
- [x] The page names important derived quantities that are not persisted as canonical state.
- [x] The future-path note preserves the core ownership rule instead of opening a second canonical state model.
