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
