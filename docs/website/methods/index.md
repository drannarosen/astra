# Methods

ASTRA's solve pipeline is the computational half of the classical lane: `Physics` defines the equations, `Methods` explains how ASTRA turns them into a nonlinear system, and the solver then works on that system as a coupled whole.

## What this section covers

The method pages document the current bootstrap implementation, not a future target:

- how the unknown vector is packed,
- how the residual vector is assembled,
- which Jacobian rows are analytic and which still use central differences,
- how luminosity scaling is handled in `erg/s`,
- how Newton damping and backtracking decide accepted steps,
- how the initial model is seeded,
- how center and surface boundary conditions are realized,
- and how the verification ladder keeps the solve honest.

## Reading order

Start with [From Equations to Residual](from-equations-to-residual.md) to see the unknown vector and residual vector, then read [Staggered Mesh and State Layout](staggered-mesh-and-state-layout.md) for ownership, [Residual Assembly](residual-assembly.md) for the row-by-row equations, and [Jacobian Construction](jacobian-construction.md) for the analytic rows and central differences. The remaining pages explain scaling, Newton progress, seeding, boundary-condition realization, and verification.

## Current scope

This is the classical bootstrap solve pipeline only. The canonical public surface is still `solve_structure(problem; state = guess)`, with `model.structure` treated as solve-owned and the other blocks attached to the returned `StellarModel`.
