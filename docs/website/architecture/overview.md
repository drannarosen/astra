# Architecture Overview

ASTRA is organized around one question: **what belongs to physics, what belongs to numerics, and what belongs to orchestration?**

This page is the high-level map of the codebase and the responsibilities of its main parts.

The bootstrap architecture answers that explicitly. In this page's language, when a component **owns** something, it is the authoritative place where that quantity, operation, or decision is defined or updated.

- `foundation/` owns the basic model language of the package: constants, configuration, grids, core types, and state construction. This is the layer that tells ASTRA what kind of model it is holding.
- `microphysics/` owns the closure interfaces for the EOS (equation of state), opacity, nuclear heating, and convection. These modules answer local physics questions such as "what pressure does this density and temperature imply?" They do not own the global solve.
- `numerics/` owns the discrete nonlinear system: the **residual** is the collection of equations ASTRA is trying to drive to zero, and the **Jacobian** is the derivative information that tells the solver how those equations change when the state changes.
- `solvers/` owns the linear and nonlinear iteration logic. This is where ASTRA decides how to take a Newton step, when to damp it, and how to solve the linearized system.
- `formulations/` owns the choice of **formulation**, meaning the mathematical method ASTRA has chosen for a solve. The classical baseline and Entropy-DAE belong here as different formulation lanes.
- `evolution/` is present only as a stub until the classical baseline is trustworthy. Its job will be timestep-aware orchestration once ASTRA moves beyond the current bootstrap structure solve.

This separation is the main architectural guardrail against the codebase collapsing into monolithic-code sprawl. It also makes the source tree teach the architecture directly instead of leaving students to infer it from a flat list of files.

## Contracts come first

In ASTRA, a **contract** is a clear rule about which part of the code is responsible for storing, updating, or computing something. ASTRA treats these ownership contracts as part of the architecture rather than as implementation trivia.

The key near-term contract is:

- a **structure block**: the part of the model the nonlinear solve is allowed to update directly,
- a **composition block**: persistent model state now, and later part of evolution-aware updates,
- an **evolution block**: the home for timestep-aware quantities and orchestration state,
- and **derived closures**: quantities such as EOS pressure that microphysics computes from state rather than stores in the solve vector.

That design now appears directly in the bootstrap implementation through `StellarModel`, `StructureState`, `CompositionState`, and `EvolutionState`. The older `StellarState` scaffold still exists internally for transition purposes, but it is not the public architecture ASTRA is building toward.

## Why this separation matters

In a stellar code, the same number can easily try to play three different roles at once: **persistent model truth** (the value stored as part of the model), **nonlinear-solve unknown** (the value the solver is actively adjusting), and **derived diagnostic** (a value computed from the state for interpretation or reporting). ASTRA is trying to prevent that confusion early.

If a contributor can answer "who owns this quantity?" before they answer "where is it stored?", the architecture is doing its job.
