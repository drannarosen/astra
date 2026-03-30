# Solver Architecture

ASTRA's current classical solver stack is intentionally modest. It is not yet a research-grade stellar-structure solver. Its purpose is to establish a truthful and inspectable solve architecture: a clear solve-owned state, a readable residual, a controlled Jacobian path, and diagnostics that report success and failure honestly. This page documents the solver architecture for ASTRA's current classical baseline lane, not the full future formulation space.

## Current classical solve loop

The bootstrap solver currently performs four main operations:

1. **Residual assembly**
   Evaluate the nonlinear structure equations for the current solve-owned state.

2. **Jacobian construction**
   Build derivative information for how those equations change with the solve-owned unknowns.

3. **Newton update and damping**
   Compute trial updates, apply backtracking, and use rescue paths only as numerical fallback.

4. **Diagnostic reporting**
   Record what happened in an explicit diagnostic object without rewriting failure as success.

In plain language, the current solver architecture is: equations, derivatives, updates, and reporting.

## Solve boundary

The classical lane is organized around the ownership contract documented elsewhere in this section:

- `model.structure` is the solve-owned block,
- microphysics supplies closures,
- evolution owns timestep-aware metadata,
- and diagnostics report what happened without becoming state.

In the current classical lane, the solver owns only the solve-owned structure block. It may read composition state, closure outputs, and evolution metadata, but it does not own those layers and should not silently mutate them. Diagnostics record solver behavior without becoming part of the canonical stellar model.

A numerical update is not scientifically acceptable if it leaves the solve-owned state outside the declared physical validity domain. In practice that means the solver architecture must continue to respect positivity, mesh consistency, and other state-validity constraints when deciding whether a trial step is acceptable.

## Approved classical contract

The intended residual order is:

1. center boundary conditions,
2. interior structure equations cell by cell,
3. surface boundary conditions.

The intended state staggering is:

- face-centered `ln r` and `L`,
- cell-centered `ln T` and `ln rho`.

Those are not just numerical implementation details. Together they define the current canonical solver contract.

## Conditioning and rescue paths

Current implementation:

- dense linearized Newton systems,
- column scaling on the solve-owned state,
- explicit weighted residual and correction metrics for step control,
- and fallback regularized normal-equation solves when the direct path struggles.

Column scaling is a conditioning choice, not a change in physical ownership. ASTRA keeps solve-owned luminosity in cgs `erg/s`, so scaling exists to improve numerical behavior, not to redefine the state.

The weighted residual and correction metrics are the next layer of the same policy. They are solver-owned numerical control surfaces, not a redefinition of the residual or of the packed structure variables. The current controller accepts a trial step only if the weighted residual metric decreases and the raw residual norm does not increase.

The canonical Methods explanation for that controller now lives in [Nonlinear Step Metrics and Globalization](../methods/nonlinear-step-metrics-and-globalization.md).

Approved direction:

- better-conditioned state scaling as the classical lane matures,
- a merit-function globalization layer built on the same weighted residual metric,
- more structured Jacobian-aware linear algebra when the operator contract stabilizes,
- and rescue paths treated as diagnostics-worthy fallback behavior, not as scientific success criteria.

## Diagnostics and failure reporting

The diagnostics layer is not decorative. It records raw residual norms, weighted residual norms, damping history, weighted correction histories, accepted steps, rejected trials, formulation identity, and explicit notes about the solve boundary.

That matters because early ASTRA needs truthful failure reporting as much as it needs successful solves. A solver architecture that cannot explain what happened is not ready to guide later scientific work.

It is also useful to distinguish two ideas that can blur later if they are not named early:

- **diagnostics** are the record of what happened during a solve attempt,
- **controller memory** or evolution metadata are inputs to future timesteps and belong to the evolution-owned layer, not to the solver diagnostics.

## Solver outcome contract

A classical solve attempt may end in several scientifically different states:

- **converged**: the declared convergence tests are satisfied,
- **damped but accepted**: convergence is reached after backtracking,
- **numerically rescued**: fallback linear algebra is used and the result still requires explicit scrutiny,
- **failed**: nonlinear convergence is not obtained or an acceptable state is not recovered.

These outcomes should remain explicitly visible in diagnostics. No solver outcome should be silently upgraded to success by vague language.

## Differentiability boundary

The next differentiability question is not "how do we backpropagate through every Newton iterate?" The better question is: what derivative object belongs to a converged solve?

For ASTRA, the clean answer is the derivative of the **solution map**: the rule that sends problem inputs to the converged solved state. That boundary is defined by the nonlinear system

$$
R(U^\ast; p) = 0,
$$

not the derivative of the full iteration transcript. That distinction matters because ASTRA's long-term differentiability strategy should attach derivative meaning to the converged nonlinear solve, not to the accidental history of line searches, damping trials, or rescue paths.

The classical solver therefore needs a stable mathematical identity before it becomes a differentiable computational primitive. That is why the classical baseline needs to become trustworthy before ASTRA tries to make later workflows fully differentiable.

## Internal QA checklist

### Solver contract clarity

- [x] The page says clearly that the current stack is modest but truthful.
- [x] The four solver operations are defined in plain language.
- [x] The solve boundary states what the solver owns, what it reads, and what it must not silently mutate.
- [x] The solve-owned state, residual ordering, and staggering are presented as part of one contract.

### Numerical control and reporting

- [x] Column scaling is explained as conditioning rather than ownership drift.
- [x] Rescue paths are described as fallback behavior, not scientific success criteria.
- [x] Diagnostics are treated as an architectural surface, not an afterthought.
- [x] The page distinguishes diagnostics from future evolution/controller memory.

### Outcomes and future direction

- [x] The solver outcome contract distinguishes converged, damped, rescued, and failed outcomes.
- [x] The page states that valid updates must respect the state validity domain.
- [x] The differentiability section attaches derivative meaning to the converged solution map rather than to the Newton transcript.
