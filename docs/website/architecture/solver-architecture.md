# Solver Architecture

The bootstrap solver stack is intentionally honest:

- the residual is a toy analytic reference-profile system,
- the Jacobian is finite-difference,
- the nonlinear loop is a plain Newton-style iteration,
- convergence is tracked explicitly in diagnostics.

This is not yet a research-grade stellar-structure solver. It is the minimal truthful surface that lets ASTRA stabilize:

- state vector layout,
- residual ownership,
- Jacobian plumbing,
- formulation dispatch,
- and developer workflows.

The first serious scientific upgrade is to replace the toy residual with a classical hydrostatic structure residual while keeping the same architectural boundaries.

## Approved direction for the classical lane

The first serious classical residual should be organized around the ownership contract now documented in the architecture section:

- solve-owned structure block,
- evolution-owned timestep bookkeeping,
- microphysics-owned closures,
- diagnostics-owned derived reports.

The intended physical ordering of the residual is:

1. center boundary conditions,
2. interior structure equations cell by cell,
3. surface boundary conditions.

The intended state staggering is:

- face-centered `ln r` and `L`,
- cell-centered `ln T` and `ln rho`.

That staggering is not just a numerical detail. It is part of the canonical solver contract.
