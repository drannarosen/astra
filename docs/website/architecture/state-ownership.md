# State Ownership

ASTRA's first serious classical lane treats the stellar model as a bundle of explicitly owned sub-states rather than one giant undifferentiated vector. That is not just a data-layout preference. It is how the code keeps clear which quantities are long-lived model state, which quantities the current solver may update, and which quantities are only derived when needed.

## Canonical conceptual split

The public model contract is:

- `StructureState`
- `CompositionState`
- `EvolutionState`

Those three blocks are bundled by `StellarModel`. The older bootstrap `StellarState` still exists as an internal transitional scaffold, but it is not the public ownership model ASTRA is teaching contributors to use.

## StructureState

`StructureState` is the current **solve-owned** block. In plain language, it is the part of the model the classical nonlinear solve is allowed to change directly.

Its approved centering is:

- face-centered `ln_r_face`,
- face-centered `luminosity_face`,
- cell-centered `ln_T_cell`,
- cell-centered `ln_rho_cell`.

This staggering matches the physical roles of the variables in a mass-coordinate stellar solver. Radius and luminosity naturally live on shell faces, while temperature and density naturally describe cell interiors.

When you read the code, the key ownership question is simple: what gets packed into the Newton vector? In the current contract, only `model.structure` crosses that boundary.

## CompositionState

`CompositionState` stores the explicit bulk composition carried by the model:

- `X_cell`,
- `Y_cell`,
- `Z_cell`.

Physically, these arrays describe what the stellar material is made of in each cell. They are persistent state even when the current structure solve keeps them fixed. That is an important ASTRA habit: the structure equations depend on composition, but that dependence does not automatically make composition solve-owned.

The most important invariant is simple: all fractions stay non-negative and `X + Y + Z = 1` in each cell up to the declared tolerance.

## EvolutionState

`EvolutionState` owns timestep-aware metadata such as age, timestep size, previous accepted timestep, accepted-step counters, rejected-step counters, and later energy-bookkeeping data.

Physically, this is the part of the model that belongs to time evolution rather than to one fixed structure solve. Keeping it separate matters because later gravothermal terms and acceptance logic should have a real home instead of drifting into ad hoc diagnostics.

## Reserved future path

The bulk-composition layer is intentionally not the endpoint. ASTRA should later grow into richer composition representations, including isotope vectors, transport fluxes, reconstructed interface abundances, and more realistic burning or mixing operators.

The ownership rule should stay the same even as the physics grows: cell-centered composition is the canonical persisted state, while any face-based composition quantity belongs to a transport or reconstruction operator rather than to the core stored model.

## Ownership checklist

- [x] The page states the public `StructureState` / `CompositionState` / `EvolutionState` split.
- [x] The page explains that only `model.structure` is currently solve-owned.
- [x] The page explains why composition remains persistent state even when frozen during the first structure solves.
- [x] The page gives evolution-aware quantities a dedicated owner instead of treating them as loose diagnostics.
- [x] The future-path note preserves the core ownership rule instead of opening a second canonical state model.
