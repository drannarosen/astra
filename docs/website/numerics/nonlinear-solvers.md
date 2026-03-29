# Nonlinear Solvers

The current nonlinear solver is a plain Newton-style loop with:

- residual evaluation,
- block-aware Jacobian assembly,
- a column-scaled dense linear solve,
- bounded damping / backtracking checks,
- a regularized normal-equation retry ladder when the direct solve is singular or unhelpful,
- explicit convergence bookkeeping.

This is enough for Milestone 0 and Milestone 1 because it stabilizes the solver-facing interfaces before ASTRA commits to more specialized numerics.

## What Newton is and is not doing here

In bootstrap ASTRA, Newton is now applied to the first classical stellar-structure residual slice. That is more meaningful than the old reference-profile scaffold, and the public default path now does take a real residual-reducing step on the placeholder-closure stack. It is still not a trustworthy hydrostatic solver yet because the examples remain non-converged and the Jacobian is still partly local finite-difference fallback.

That still matters. It proves that ASTRA can:

- pack the solve-owned structure block,
- evaluate a consistent residual,
- build a Jacobian,
- apply scaled, regularized, and damped updates,
- and return diagnostics tied to the same ownership story.

## Current caveat

The current examples no longer stop at iteration 0, and the accepted step is now materially larger than in the previous slice. On the current 24-cell public demo, ASTRA reduces the residual norm from `2.1962008371612166e22` to `2.1275638477172188e22`, accepts exactly one step with damping `0.03125`, records `380` rejected trials, and still returns `converged = false`.

That is scientifically useful because it proves there is a residual-reducing direction on the current placeholder-closure stack and that solver-side luminosity conditioning plus center asymptotics improved the usable step. It is also a warning sign: the basin is still extremely narrow, so the next blocker remains update quality and Jacobian fidelity rather than missing ownership, missing diagnostics, or missing solver-boundary language.
