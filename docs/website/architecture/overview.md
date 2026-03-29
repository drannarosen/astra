# Architecture Overview

ASTRA is organized around one question: **what belongs to physics, what belongs to numerics, and what belongs to orchestration?**

The bootstrap architecture answers that explicitly:

- `microphysics/` owns EOS, opacity, nuclear, and convection interfaces,
- `residuals.jl` and `jacobians.jl` own the discrete nonlinear system,
- `solvers/` owns linear and nonlinear iteration logic,
- `formulations/` owns the choice of method,
- `evolution/` is present only as a stub until the classical baseline is trustworthy.

This separation is the main architectural guardrail against mini-MESA sprawl.
