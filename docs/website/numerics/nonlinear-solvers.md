# Nonlinear Solvers

Canonical guide: [Nonlinear Newton and Backtracking](../methods/nonlinear-newton-and-backtracking.md).

The current nonlinear solver is a plain Newton-style loop with:

- residual evaluation,
- block-aware Jacobian assembly,
- a column-scaled dense linear solve,
- bounded damping / backtracking checks,
- a regularized normal-equation retry ladder when the direct solve is singular or unhelpful,
- explicit convergence bookkeeping.

This page stays as a compact numerics-side summary and is not the canonical numerical specification. It is enough for Milestone 0 and Milestone 1 because it stabilizes the solver-facing interfaces before ASTRA commits to more specialized numerics.

## What Newton is and is not doing here

In bootstrap ASTRA, Newton is now applied to the first classical stellar-structure residual slice. That is more meaningful than the old reference-profile scaffold, and the public default path now does take a real residual-reducing step on the placeholder-closure stack. It is still not a trustworthy hydrostatic solver yet because the examples remain non-converged and the Jacobian is still partly local finite-difference fallback.

That still matters. It proves that ASTRA can:

- pack the solve-owned structure block,
- evaluate a consistent residual,
- build a Jacobian,
- apply scaled, regularized, and damped updates,
- and return diagnostics tied to the same ownership story.

## Current caveat

The current examples no longer stop at iteration 0, and the accepted-step sequence is now materially stronger than in the earlier center-conditioning slice. On the current 24-cell public demo, ASTRA reduces the residual norm from `2.1962008371612166e22` to `1.1903032914682583e19`, reaches 8 accepted steps, records 289 rejected trials, and still returns `converged = false`.

That is scientifically useful because it proves the public default path now has a sustained residual-reducing direction on the current placeholder-closure stack. It is also a warning sign: the basin is still narrow, so the next blocker remains full convergence quality rather than missing ownership, missing diagnostics, or missing solver-boundary language.

## Summary checklist

- [x] This page explicitly points back to the canonical numerical specification in `Methods`.
- [x] This page explicitly says it is not the canonical numerical specification.
- [ ] Quantitative Newton acceptance and failure semantics stay owned by [Nonlinear Newton and Backtracking](../methods/nonlinear-newton-and-backtracking.md).
