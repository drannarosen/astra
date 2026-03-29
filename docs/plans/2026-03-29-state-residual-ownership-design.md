# ASTRA State And Residual Ownership Design

Date: **March 29, 2026**

This note records the approved design direction for ASTRA's first serious classical structure and evolution lane.

## Motivation

ASTRA's bootstrap package currently proves package integrity, type discipline, a toy nonlinear solve surface, and documentation structure. It does **not** yet prove the classical stellar structure equations. Before implementing that solver, ASTRA needs an explicit ownership contract for:

- the persistent model state,
- the nonlinear solve unknowns,
- the residual ordering,
- the boundary between structure, evolution, and microphysics,
- and the future path from bulk composition to isotope vectors and transport fluxes.

The goal is to prevent the first real solar PMS to ZAMS to main-sequence lane from being defined by accidental implementation choices.

## Scientific target

The first flagship science lane for ASTRA should be:

- a **single-star**, **1D**, **hydrostatic** solar-mass model,
- evolved from the **pre-main sequence** through **ZAMS** and onto the **main sequence**,
- with the first reference target being the **present-day Sun** at its current age.

This is not the first numerical milestone, but it is the first serious scientific program that should shape the near-term architecture.

## Approved ownership model

### Top-level model

ASTRA should move toward a top-level `StellarModel`-style container with explicit sub-blocks:

- `StructureState`
- `CompositionState`
- `EvolutionState`
- grid and configuration references

This replaces the idea that one flat state object should silently mix all roles.

### StructureState

`StructureState` is the canonical nonlinear solve block for the classical baseline.

Approved centering:

- **face-centered**: `ln_r_face`, `luminosity_face`
- **cell-centered**: `ln_T_cell`, `ln_rho_cell`

This matches the common MESA-style staggering of thermodynamic quantities in cells and geometry / luminosity variables at faces. See the MESA debugging docs for the listed structure variables `i_lnd`, `i_lnT`, `i_lnR`, and `i_lum`, where density and temperature are cell averages and radius and luminosity are at the outer face of a cell: [MESA debugging docs](https://docs.mesastar.org/en/release-r22.05.1/developing/debugging.html).

### CompositionState

For the first classical and solar-evolution lane, `CompositionState` should store explicit, cell-centered bulk composition arrays:

- `X_cell`
- `Y_cell`
- `Z_cell`

These are the persistent physical composition state of the model.

Approved invariants:

- `X + Y + Z = 1` in every cell up to declared tolerance
- all composition fractions are non-negative

Composition is **not** part of the initial nonlinear structure solve vector.

### EvolutionState

`EvolutionState` should own timestep-aware metadata such as:

- stellar age,
- current timestep,
- previous accepted timestep,
- accepted / rejected step counters,
- and later bookkeeping relevant to energy accounting.

This layer is where gravothermal source-term bookkeeping should live.

## Residual ownership

The classical residual should own the equation semantics, while microphysics owns closures and evolution owns timestep-aware source bookkeeping.

### Interior equation set

For each interior cell, the classical lane should conceptually carry four structure equations:

1. geometric / mass-continuity equation,
2. hydrostatic-equilibrium equation,
3. luminosity / energy equation,
4. temperature-gradient / transport equation.

### Thermodynamic closure

The EOS should be treated as a closure in a `rho, T, composition` basis. Pressure and thermodynamic derivatives are derived from the EOS rather than treated as canonical state variables. This is well aligned with MESA's EOS interface, which describes density and temperature as the primary independent variables: [MESA EOS overview](https://docs.mesastar.org/en/stable/eos/overview.html).

### Source-decomposed energy equation

The energy equation should be designed from the start with explicit slots for:

- `eps_nuc`,
- `eps_grav`,
- and loss terms.

Some of these can be stubbed initially, but the ownership should be correct from the beginning because PMS evolution requires gravothermal energy release.

## Residual ordering

Approved canonical ordering:

1. center boundary conditions,
2. interior structure equations cell by cell,
3. surface boundary conditions.

This keeps the residual ordering physically legible and aligned with the state staggering.

## Composition: future extension path

ASTRA's initial bulk-composition design is not intended to be the endpoint.

The composition layer should reserve an explicit future path for:

- cell-centered isotope-vector composition,
- transport operators that compute face fluxes,
- reconstructed interface abundances,
- diffusive and advective flux bookkeeping,
- and longer-timescale burning / mixing workflows.

Crucially, the future design should preserve the same ownership rule:

- **cell-centered composition is the canonical persisted state**
- **face composition and composition fluxes are operator-owned transport quantities**

This is consistent with the way MESA stores abundance variables as model truth in `xa(:,:)` while also constructing face-based mixing flows and reconstructed values when transport or remeshing needs them. See the MESA developer tour and test-suite profile metadata: [MESA developer tour](https://docs.mesastar.org/en/release-r22.05.1/developing/tour.html), [MESA test suite profile metadata](https://docs.mesastar.org/en/release-r23.05.1/test_suite/simplex_solar_calibration.html).

## Consequences for ASTRA implementation

This design implies the following near-term code changes:

- split the conceptual state contract in the docs before splitting code mechanically,
- teach the handbook that the current flat bootstrap `StellarState` is transitional,
- preserve the current `ln_r`, `L`, `ln_T`, `ln_rho` ordering in pack/unpack logic,
- prepare for a later `StructureState` / `CompositionState` refactor,
- and keep composition outside the initial Newton unknown vector.

## Out of scope for this design note

This note does **not** yet decide:

- the exact discrete finite-volume formulas,
- the exact surface boundary prescription,
- the timestep acceptance criteria,
- the isotope-network interface,
- or the production microphysics data format.

Those should be downstream design notes, not hidden inside the first ownership contract.
