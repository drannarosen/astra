# Nonlinear Solvers

The current nonlinear solver is a plain Newton-style loop with:

- residual evaluation,
- block-aware Jacobian assembly,
- dense linear solve,
- bounded damping / backtracking checks,
- explicit convergence bookkeeping.

This is enough for Milestone 0 and Milestone 1 because it stabilizes the solver-facing interfaces before ASTRA commits to more specialized numerics.

## What Newton is and is not doing here

In bootstrap ASTRA, Newton is now applied to the first classical stellar-structure residual slice. That is more meaningful than the old reference-profile scaffold, but it is still not a trustworthy hydrostatic solver yet because the examples remain non-converged and the Jacobian is still partly local finite-difference fallback.

That still matters. It proves that ASTRA can:

- pack the solve-owned structure block,
- evaluate a consistent residual,
- build a Jacobian,
- apply damped updates,
- and return diagnostics tied to the same ownership story.

## Current caveat

The current examples still stop at iteration 0 with `converged = false`. The remaining blocker is no longer missing residual ownership or missing Jacobian structure; it is the quality of the Newton update and the fidelity of the assembled Jacobian.
