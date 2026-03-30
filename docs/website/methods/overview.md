# Methods

ASTRA's solve pipeline is the computational half of the classical lane: `Physics` defines the equations, `Methods` explains how ASTRA turns them into a nonlinear system, and the solver then works on that system as a coupled whole.

If you need the continuous equations first, start in [Physics](../physics/overview.md). If you need source-backed MESA comparison notes for solver hardening, use the [MESA Reference](mesa-reference/overview.md) subtree alongside these ASTRA-specific pages.

These pages are intended to be specification-grade for the current numerics. If the code and the methods docs disagree about variable ownership, row meaning, sign conventions, or derivative basis, that discrepancy should be treated as a bug to resolve rather than as harmless documentation drift.

This section is the canonical numerical specification section for ASTRA. The older [Numerics](../numerics/residuals.md) pages remain useful as short summaries, but they are intentionally secondary. If a contributor needs the authoritative answer to a numerics question, this section should be the place they land.

The current surface atmosphere story is split between this section and [Atmosphere and Photosphere](../physics/atmosphere-and-photosphere.md). Read them together when tracing the outer rows.

## What this section covers

The method pages document the current bootstrap implementation, not a future target:

- how the unknown vector is packed,
- how the residual vector is assembled,
- which Jacobian rows are analytic and which still use central differences,
- how luminosity scaling is handled in `erg/s`,
- how weighted residual and correction metrics control current Newton steps,
- how Newton damping and backtracking decide accepted steps,
- how the initial model is seeded,
- how center and surface boundary conditions are realized,
- and how the verification ladder keeps the solve honest.

## Reading order

Start with [From Equations to Residual](from-equations-to-residual.md) to see the unknown vector and residual vector, then read [Staggered Mesh and State Layout](staggered-mesh-and-state-layout.md) for ownership, [Residual Assembly](residual-assembly.md) for the row-by-row equations, and [Jacobian Construction](jacobian-construction.md) for the analytic rows and central differences. The remaining pages explain scaling, weighted step metrics, Newton progress, seeding, boundary-condition realization, and verification.

The physical companion surface is [Physics](../physics/overview.md). For the atmosphere boundary specifically, start with [Atmosphere and Photosphere](../physics/atmosphere-and-photosphere.md). For source-backed comparison notes against the local MESA mirror, see [MESA Reference](mesa-reference/overview.md).

For new research students, the simplest way to use this section is to follow one question across pages:

1. What is the continuous equation trying to say?
2. Which discrete ASTRA residual row owns it?
3. Which packed variables does that row depend on?
4. Which Jacobian entries are analytic and which are still fallback?
5. How are the linear solve, weighted step metrics, and Newton acceptance conditioned?
6. What does MESA do in the same neighborhood, and is the comparison file-backed or only analogous?

## Current scope

This is the classical bootstrap solve pipeline only. The canonical public surface is still `solve_structure(problem; state = guess)`, with `model.structure` treated as solve-owned and the other blocks attached to the returned `StellarModel`.

## Methods handbook checklist

- [x] The section explicitly claims canonical ownership of the current numerical specification.
- [x] The reading order carries a contributor from continuous equation to residual, Jacobian, scaling, and verification.
- [x] The MESA comparison subtree is linked as a source-backed reference surface rather than as ASTRA's own specification.
- [ ] Every major methods page ends with updateable implementation, validation, and open-risk checklists.
- [ ] The docs tests enforce the summary-only status of the `Numerics` section and the canonical status of `Methods`.
