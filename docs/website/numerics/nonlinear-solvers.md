# Nonlinear Solvers

Canonical guides: [Nonlinear Step Metrics and Globalization](../methods/nonlinear-step-metrics-and-globalization.md) and [Nonlinear Newton and Backtracking](../methods/nonlinear-newton-and-backtracking.md).

The current nonlinear solver is a plain Newton-style loop with:

- residual evaluation,
- block-aware Jacobian assembly,
- a column-scaled dense linear solve,
- explicit weighted residual and correction metrics,
- bounded damping / backtracking checks,
- a regularized normal-equation retry ladder when the direct solve is singular or unhelpful,
- explicit convergence bookkeeping.

This page stays as a compact numerics-side summary and is not the canonical numerical specification. It is enough for Milestone 0 and Milestone 1 because it stabilizes the solver-facing interfaces before ASTRA commits to more specialized numerics.

## What Newton is and is not doing here

In bootstrap ASTRA, Newton is now applied to the first classical stellar-structure residual slice. That is more meaningful than the old reference-profile scaffold, and the public default path now does take a real weighted-metric-guided residual-reducing step on the placeholder-closure stack. It is still not a trustworthy hydrostatic solver yet because the examples remain non-converged and the Jacobian is still partly local finite-difference fallback.

That still matters. It proves that ASTRA can:

- pack the solve-owned structure block,
- evaluate a consistent residual,
- build a Jacobian,
- apply scaled, weighted, regularized, and damped updates,
- and return diagnostics tied to the same ownership story.

## Current caveat

The current examples no longer stop at iteration 0, but the basin is still narrow. On the current 12-cell default test fixture, ASTRA lowers the weighted residual metric from `1.9937898964950228e6` to `7.377697572625385e5`, lowers the raw residual norm from `4.48256242518452e22` to `4.482447133127383e22`, accepts 1 step, records 360 rejected trials, and still returns `converged = false`.

That is scientifically useful because it proves the public default path now has a weighted-metric-guided residual-reducing direction on the current placeholder-closure stack. It is also a warning sign: the basin is still narrow, so the next blocker remains stronger globalization rather than missing ownership, missing diagnostics, or missing solver-boundary language.

## Summary checklist

- [x] This page explicitly points back to the canonical numerical specification in `Methods`.
- [x] This page explicitly says it is not the canonical numerical specification.
- [x] Quantitative Newton acceptance and failure semantics stay owned by the `Methods` nonlinear-controller pages.
