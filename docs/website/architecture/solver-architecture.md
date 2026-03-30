# Solver Architecture

ASTRA's current classical solver stack is intentionally modest. It is not yet a research-grade stellar-structure solver. What it does provide is the first truthful architectural surface where ASTRA can stabilize the solve-owned state, the residual meaning, the Jacobian path, and the diagnostics that report success or failure honestly.

## The current stack

At a high level, the bootstrap solver does four things:

- assembles a classical residual from the current model,
- builds a Jacobian, meaning derivative information for how those equations change when the state changes,
- takes Newton-style updates with backtracking and regularized fallback solves,
- and records what happened in explicit diagnostics rather than hiding failure behind optimistic language.

That is the current solver architecture in plain language: equations, derivatives, updates, and reporting.

## The approved classical direction

The classical lane is organized around the ownership contract documented elsewhere in this section:

- `model.structure` is the solve-owned block,
- microphysics supplies closures,
- evolution owns timestep-aware metadata,
- and diagnostics report what happened without becoming state.

The intended residual order is:

1. center boundary conditions,
2. interior structure equations cell by cell,
3. surface boundary conditions.

The intended state staggering is:

- face-centered `ln r` and `L`,
- cell-centered `ln T` and `ln rho`.

Those are not just numerical implementation details. Together they define the current canonical solver contract.

## Linear algebra and conditioning

ASTRA currently solves dense linearized Newton systems. It also applies column scaling to the solve-owned state, especially because luminosity remains in cgs `erg/s`. That scaling is a conditioning choice, not a change in physical ownership.

When the direct solve struggles, the current bootstrap path can fall back to regularized normal-equation solves. That is best understood as a numerical rescue path, not as a scientific success criterion.

## Diagnostics are part of the architecture

The diagnostics layer is not decorative. It records residual norms, damping history, accepted steps, rejected trials, formulation identity, and explicit notes about the solve boundary.

That matters because early ASTRA needs truthful failure reporting as much as it needs successful solves. A solver architecture that cannot explain what happened is not ready to guide later scientific work.

## Solver architecture versus differentiability

The next differentiability question is not "how do we backpropagate through every Newton iterate?" The better question is: what derivative object belongs to a converged solve?

For ASTRA, the clean answer is the derivative of the **solution map** defined by the nonlinear system

$$
R(U^\ast; p) = 0,
$$

not the derivative of the full iteration transcript. That is why the classical baseline needs to become trustworthy before ASTRA tries to make later workflows fully differentiable.

## Solver checklist

- [x] The page says clearly that the current stack is modest but truthful.
- [x] The four solver jobs are defined in plain language.
- [x] The solve-owned state, residual ordering, and staggering are presented as part of one contract.
- [x] Column scaling is explained as conditioning rather than ownership drift.
- [x] Diagnostics are treated as an architectural surface, not an afterthought.
