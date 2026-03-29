# Contracts Overview

ASTRA uses the word **contract** in a strict engineering sense: a contract says which layer owns a quantity, what that quantity means physically, and whether it is solve-owned, evolution-owned, or derived-only.

This is one of the most important architectural ideas in the repository. It is what keeps ASTRA from drifting into a codebase where the same symbol quietly means different things in the solver, the timestepper, and the diagnostics.

## Why contracts matter in a stellar code

In a forward stellar code, three different questions can look similar if the architecture is vague:

1. what belongs to the persistent stellar model,
2. what belongs to one nonlinear solve at a fixed timestep,
3. what is merely a derived diagnostic.

ASTRA wants these to stay separate.

That is especially important for the first serious science target: a solar-mass model evolved from the pre-main sequence through ZAMS and onto the main sequence. If ownership is muddy, then residuals, source terms, and validation logic all become hard to reason about.

## Current ASTRA status

The current codebase now exposes an explicit `StellarModel` with separate `StructureState`, `CompositionState`, and `EvolutionState` blocks.

An internal bootstrap `StellarState` helper still exists only as transitional legacy scaffolding for the old solver path. It is not part of the public ownership contract.

The approved near-term architecture now appears directly in code as three explicit conceptual blocks:

- `StructureState`
- `CompositionState`
- `EvolutionState`

The handbook should therefore be read as a description of the current public contract, not merely of a future target.

## Contract layers

### StructureState

The classical baseline structure solve owns:

- face-centered `ln r`,
- face-centered `L`,
- cell-centered `ln T`,
- cell-centered `ln rho`.

### CompositionState

The first solar-capable lane stores explicit cell-centered bulk composition:

- `X`,
- `Y`,
- `Z`.

Composition is persistent physical state, but it is not part of the initial Newton unknown vector.

### EvolutionState

The evolution layer owns timestep-aware quantities such as age, timestep size, and later gravothermal bookkeeping.

### Derived closures

The EOS, opacity, nuclear, and convection layers provide closures and coefficients. They are not the canonical model state.

## Worked ownership example

Suppose ASTRA needs pressure at one cell during residual assembly. The canonical persisted model state is:

- `rho` from `model.structure`,
- composition from `model.composition`,
- and any timestep-aware bookkeeping later from `model.evolution`.

Pressure itself is then produced by the EOS closure. That means pressure is essential, but it is still not solve-owned or persisted as a primary state variable in the current contract.

## Physical residual ordering

ASTRA's classical residual contract should read in physical order:

1. center boundary conditions,
2. interior structure equations cell by cell,
3. surface boundary conditions.

That ordering is not just aesthetic. It keeps the solver, diagnostics, and Jacobian structure aligned with the physical model.

## Why ASTRA follows this pattern

This design is strongly informed by MESA's common 1D staggering, where density and temperature are cell-centered and radius and luminosity are face-based, while the EOS works naturally in a density-temperature basis. See the official MESA debugging docs and EOS overview for reference: [MESA debugging docs](https://docs.mesastar.org/en/release-r22.05.1/developing/debugging.html), [MESA EOS overview](https://docs.mesastar.org/en/stable/eos/overview.html).

ASTRA should learn from that pattern without inheriting MESA's full historical complexity.
