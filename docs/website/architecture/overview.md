# Architecture Overview

ASTRA is organized around one question: **what belongs to physics, what belongs to numerics, and what belongs to orchestration?**

The bootstrap architecture answers that explicitly:

- `microphysics/` owns EOS, opacity, nuclear, and convection interfaces,
- `residuals.jl` and `jacobians.jl` own the discrete nonlinear system,
- `solvers/` owns linear and nonlinear iteration logic,
- `formulations/` owns the choice of method,
- `evolution/` is present only as a stub until the classical baseline is trustworthy.

This separation is the main architectural guardrail against mini-MESA sprawl.

## Contracts come first

ASTRA now treats explicit ownership contracts as part of the architecture rather than as implementation trivia.

The key near-term contract is:

- a **structure block** owned by the nonlinear solve,
- a **composition block** owned by the persistent stellar model and later by the evolution layer,
- an **evolution block** owned by timestep-aware orchestration,
- and **derived closures** owned by microphysics rather than by the state vector itself.

That design now appears directly in the bootstrap implementation through `StellarModel`, `StructureState`, `CompositionState`, and `EvolutionState`. The remaining internal `StellarState` scaffold is transitional legacy support rather than the current public architecture.
