# Nonlinear Solvers

The current nonlinear solver is a plain Newton-style loop with:

- residual evaluation,
- finite-difference Jacobian construction,
- dense linear solve,
- damping,
- explicit convergence bookkeeping.

This is enough for Milestone 0 and Milestone 1 because it stabilizes the solver-facing interfaces before ASTRA commits to more specialized numerics.

## What Newton is and is not doing here

In bootstrap ASTRA, Newton is not yet solving the full classical stellar-structure equations. It is exercising the solver contract against a toy residual with the same broad ownership shape the real solver will need later.

That still matters. It proves that ASTRA can:

- pack the solve-owned structure block,
- evaluate a consistent residual,
- build a Jacobian,
- apply damped updates,
- and return diagnostics tied to the same ownership story.
