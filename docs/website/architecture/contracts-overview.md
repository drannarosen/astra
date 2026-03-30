# Contracts Overview

ASTRA uses the word **contract** in a strict engineering sense. A contract is a clear rule about which part of the code is responsible for storing, updating, or computing something, and what that thing means physically. In ASTRA, contracts matter because the same symbol can otherwise slide between physics, numerics, and orchestration until nobody is quite sure which layer is actually in charge.

In this page, **ownership** means that responsibility in plain language: when a layer owns a quantity, it is the authoritative place responsible for storing it, updating it, or computing it. That is how ASTRA keeps the code scientifically legible instead of letting important quantities drift into "it depends" territory.

## Why contracts matter in a stellar code

In a forward stellar code, the same number can try to play three different roles at once.

1. The **persistent stellar model** is the long-lived state of the star: the information the model really carries forward from one stage of the calculation to the next.
2. **One nonlinear solve at a fixed timestep** is the smaller set of unknowns the solver is allowed to adjust while it tries to satisfy the current structure equations.
3. A **derived diagnostic** is a quantity computed from the state so we can interpret, validate, or debug the run without silently turning that quantity into canonical model state.

ASTRA wants those roles to stay separate. That matters for the first serious science target: a solar-mass model followed from the pre-main sequence through ZAMS and onto the main sequence. If ownership is muddy, then residuals, source terms, and validation logic all start to blur together.

## Current ASTRA status

The current codebase exposes an explicit `StellarModel` with separate `StructureState`, `CompositionState`, and `EvolutionState` blocks. That split is the current public **interface**, meaning the boundary this part of the code presents to the rest of ASTRA. It is also the current public contract.

An internal bootstrap `StellarState` helper still exists, but only as transitional legacy scaffolding for the older solver path. It is not the public ownership contract ASTRA is building toward.

The handbook should therefore be read as a description of the current public architecture, not merely of a future target.

## Contract layers

### StructureState

`StructureState` owns the quantities the current classical structure solve may update directly: face-centered `ln r`, face-centered `L`, cell-centered `ln T`, and cell-centered `ln rho`.

Physically, this is the star's present structural configuration in the classical lane. In ASTRA's language these variables are **solve-owned**, meaning the current nonlinear structure solve is allowed to move them directly. `StructureState` does **not** own composition history, timestep bookkeeping, or closure outputs such as pressure.

### CompositionState

`CompositionState` owns the explicit bulk composition carried by the model, such as `X`, `Y`, and `Z`.

Physically, this is the material makeup of each cell. It is persistent model state even when it is not part of the current Newton vector. That distinction matters: the structure equations depend on composition, but dependence does not automatically make composition solve-owned.

### EvolutionState

`EvolutionState` owns timestep-aware orchestration state such as age, timestep size, and later gravothermal bookkeeping.

Physically, this is the part of the model that belongs to time evolution rather than to one fixed structure solve. These quantities are **evolution-owned**, meaning later evolution logic is responsible for updating them. `EvolutionState` does **not** own the classical structure unknowns themselves.

### Derived closures

The EOS, opacity, nuclear, and convection layers own **derived closures**: quantities and coefficients computed from state rather than stored as canonical state.

This is the key distinction between a derived quantity and canonical state. A canonical state variable is part of the authoritative stored model. A derived quantity is computed from that state when the code needs it. Pressure, opacity, and nuclear heating can all be essential for the solve while still being **derived-only** rather than primary persisted state.

## ASTRA invariants

An **invariant** is a rule the architecture should keep true even as the implementation changes. The current ASTRA ownership model depends on a few simple invariants:

- Solve-owned variables are the only variables the current structure solve may update directly.
- Composition remains persistent state even when it is not part of the current Newton vector.
- Derived closures are computed from state and are not silently treated as primary canonical state.
- Diagnostics describe the run, but they do not become the model state.

These checks are simple on purpose. They give contributors a quick way to tell whether a change preserves ASTRA's architecture or quietly blurs it.

## Worked ownership example

Suppose ASTRA needs pressure in one cell during residual assembly. Pressure is important because the hydrostatic and transport equations need it. That importance can tempt a codebase to store pressure directly as if it were automatically canonical state.

But the current ownership story is tighter than that. The canonical persisted model state is still `rho` and the other structure unknowns from `model.structure`, composition from `model.composition`, and any timestep-aware bookkeeping from `model.evolution`. Pressure is then computed by the EOS closure from that state.

That is the point of the example: "important" does not mean "persisted." In ASTRA, pressure matters enormously, but it is still derived-only in the current contract.

## Physical residual ordering

ASTRA's classical residual contract should read in physical order:

1. center boundary conditions,
2. interior structure equations cell by cell,
3. surface boundary conditions.

That ordering matters because it helps the code, the diagnostics, and the mathematical structure all line up with the physics being modeled.

## Why ASTRA follows this pattern

This design is informed by a useful MESA pattern: density and temperature are cell-centered, radius and luminosity are face-based, and the EOS works naturally in a density-temperature basis. In ASTRA's handbook, those comparisons should be read through the local source-backed pages in [Methods: MESA Reference](../methods/mesa-reference/index.md), especially [Mesh and Variables](../methods/mesa-reference/mesh-and-variables.md), rather than through memory or folklore.

ASTRA is learning from that pattern, not copying historical complexity wholesale. The goal is to keep the useful ownership structure while avoiding a codebase where every layer quietly takes responsibility for everything.

## Architecture checklist

- [x] The public contract is stated in terms of `StellarModel`, `StructureState`, `CompositionState`, and `EvolutionState`.
- [x] The page defines contract, ownership, solve-owned, evolution-owned, derived-only, invariant, and interface in ASTRA's own language.
- [x] The page states inspectable ASTRA invariants that a contributor can check against code changes.
- [x] The worked pressure example distinguishes an important derived quantity from canonical persisted state.
- [x] The residual ordering is stated in physical order so the code and the physics tell the same story.
- [ ] Every major contract page should carry equally explicit implementation, validation, and open-risk checks.
