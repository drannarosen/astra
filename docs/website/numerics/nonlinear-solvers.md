# Nonlinear Solvers

The current nonlinear solver is a plain Newton-style loop with:

- residual evaluation,
- finite-difference Jacobian construction,
- dense linear solve,
- damping,
- explicit convergence bookkeeping.

This is enough for Milestone 0 and Milestone 1 because it stabilizes the solver-facing interfaces before ASTRA commits to more specialized numerics.
