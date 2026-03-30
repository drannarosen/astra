# Nonlinear Step Metrics and Globalization

This page is the canonical specification for ASTRA's current solver-side step metrics and for the longer-term globalization direction.

For the broader future-facing argument about why ASTRA wants a merit-function backbone, how that differs from simply copying MESA's richer controller ecology, and why that still scales to an eventual all-phases stellar-evolution ambition, see [Planning: Solver Maturity and Globalization Roadmap](../planning/solver-maturity-and-globalization-roadmap.md).

The key distinction is simple:

- the **physical residual** says which stellar-structure equations ASTRA is enforcing,
- the **solver metrics** say how Newton decides whether a proposed correction is numerically acceptable.

That distinction matters because a mixed-unit residual vector does not automatically give a trustworthy notion of "step quality." Radius rows, hydrostatic rows, luminosity rows, and transport rows can all be physically meaningful while still living on very different numerical scales.

The solver therefore needs explicit metrics that improve numerical robustness without changing equation ownership.

## Why raw residual norms are fragile

ASTRA's current classical residual mixes rows with different units and natural magnitudes:

- geometry rows live on shell-volume scales,
- hydrostatic rows live on pressure scales,
- luminosity rows live on `erg/s`,
- and transport rows are already log-gradient style and therefore dimensionless.

A raw norm of that vector is honest as a diagnostic, but it is a poor universal acceptance metric. A large hydrostatic row can dominate the norm even when a luminosity correction is the real numerical problem. The opposite can also happen: a numerically dangerous luminosity correction can look harmless if the raw norm is dominated by another row family.

That is why ASTRA now separates two questions:

1. What does the residual physically mean?
2. How should Newton compare two candidate states numerically?

The first question is owned by the residual. The second is owned by the solver metrics.

## Current ASTRA policy

The immediate hardening slice keeps the classical packed state unchanged,

$$
x = (\ln R,\; L,\; \ln T,\; \ln \rho),
$$

keeps luminosity linear in cgs `erg/s`, and adds explicit weighting only on the solver side.

### Residual row weights

ASTRA now evaluates a weighted residual metric using explicit row weights.

The current row-family policy is:

- center radius row: scale by the center-series target radius,
- center luminosity row: scale by the center-series target luminosity,
- interior geometry row: scale by `max(shell volume, dm/rho)`,
- interior hydrostatic row: scale by `max(|P_k|, |P_{k+1}|, |discrete gravity term|)`,
- interior luminosity row: scale by `max(|L_k|, |L_{k+1}|, |dm * eps|)`,
- interior transport row: unit scale because it is already a log-gradient residual,
- surface radius, luminosity, temperature, and density rows: scale by their boundary targets.

The weighted residual norm is the RMS norm

$$
\|R\|_{W_r} =
\frac{\|W_r R\|_2}{\sqrt{N_R}},
$$

where `W_r` is the diagonal row-weight operator and `N_R` is the residual length.

This is still the same physical residual. ASTRA is not changing the equations. It is only changing the metric used to compare trial steps.

### Correction weights

ASTRA also tracks weighted packed corrections.

This page uses the plural phrase **correction weights** deliberately because the solver now assigns an explicit per-variable weighting policy in packed space rather than treating all correction components as numerically interchangeable.

For the current packed variables:

- `lnR`, `lnT`, and `lnrho` corrections are already dimensionless, so their correction weight is `1`,
- luminosity stays linear in `erg/s`, so its correction weight is the inverse of an explicit luminosity reference scale.

For a luminosity face `L_k`, ASTRA currently uses

$$
L_{\mathrm{ref},k} =
\max\left(|L_k|,\; |L_{\mathrm{surf,target}}|,\; |L_{\mathrm{center,floor}}|\right).
$$

That reference scale is deliberately solver-owned. It does not redefine luminosity into a logarithmic variable. It only says what ASTRA considers an order-unity luminosity correction at the current iterate.

The weighted correction RMS and max metrics are:

$$
\|\Delta x\|_{W_c} =
\frac{\|W_c \Delta x\|_2}{\sqrt{N_x}},
\qquad
\|\Delta x\|_{\infty,W_c} = \|W_c \Delta x\|_\infty.
$$

### Weighted correction limiting

Before ASTRA evaluates a trial Newton step, it now uniformly shrinks the packed correction if either weighted correction metric is too large.

The current limiter chooses a scalar factor

$$
c = \min\left(1,\; \frac{1}{\|\Delta x\|_{W_c}},\; \frac{1}{\|\Delta x\|_{\infty,W_c}}\right),
$$

and uses `c * Δx` as the candidate correction before backtracking.

This is not yet a trust region. It is a small, explicit safety layer that keeps trial steps inside a dimensionless correction envelope.

### Acceptance and convergence

ASTRA's current acceptance rule is now:

1. compute a limited correction,
2. try damped versions of that correction,
3. accept a trial only if the **weighted residual metric decreases** on the same residual definition,
4. and reject the trial if the **raw residual norm increases**, even when the weighted metric improves.

That last condition is an explicit scientific-honesty safeguard. During development of this slice, a weighted-only acceptance rule could reduce the weighted metric while allowing the raw mixed-unit residual norm to blow up by many orders of magnitude. ASTRA therefore keeps the weighted metric as the primary controller, but it does not allow a trial step to hide a catastrophic raw-residual regression.

Convergence remains tied to the weighted residual metric. Raw residuals are still recorded in diagnostics because they remain scientifically informative.

## Why luminosity needs special treatment

The current classical packed state already treats three structure variables logarithmically:

- `lnR`,
- `lnT`,
- `lnrho`.

Those variables naturally carry dimensionless corrections. Luminosity is different:

- the current classical solve keeps `L` linear in physical `erg/s`,
- `L` can be small near the center,
- and using raw `erg/s` corrections directly in a mixed packed vector creates a conditioning problem.

That is why ASTRA now treats luminosity specially in both the linear solve and the correction metrics, while still refusing to change the physical solve variable into `lnL`.

This is an example of ASTRA's broader policy: fix conditioning in the solver machinery before redefining the science variable.

## Source-backed MESA comparison

The relevant local MESA files remain:

- `star_data/public/star_data_step_work.inc`,
- `star/private/solver_support.f90`,
- `star/private/star_solver.f90`.

Those files show three patterns that were genuinely useful for ASTRA:

1. `x_scale` is explicit solver state,
2. `residual_weight` and `correction_weight` are explicit solver state,
3. correction norms and max-correction limits are part of the controller rather than accidental side effects.

ASTRA follows the idea, not the full implementation. The current classical lane is much smaller than MESA's full star solver, uses a different packed-state design, and currently keeps the policy deliberately narrow:

- no abundance solve variables in this slice,
- no full MESA-style retry ecology,
- no full trust-region or merit-function controller yet.

For the file-backed comparison details, see [MESA Reference: Solver Scaling](mesa-reference/solver-scaling.md).

## What a merit-based globalization method is

The likely best long-term ASTRA direction is a merit-based globalization scheme.

The idea is to define one scalar objective

$$
\phi(x) = \frac{1}{2}\|W_r R(x)\|_2^2,
$$

and make every globalization decision in terms of that scalar function.

This is attractive because it gives the solver one consistent question to answer:

> Does this step reduce the weighted residual objective enough to justify itself?

That immediately improves several things.

### One scalar target

A merit function turns the coupled residual into one explicit objective. That makes line search, trust-region logic, and regularization decisions easier to interpret than a mixture of ad hoc rules.

### Predicted versus actual decrease

Once ASTRA has a scalar merit function, it can compare:

- the decrease predicted by the linearized Newton model,
- against the decrease actually observed after evaluating the nonlinear residual.

That comparison is the heart of modern globalization logic. It tells the solver whether a step failed because:

- the Jacobian model was poor,
- the step was too large,
- the weighting policy was misleading,
- or the problem itself is locally hard.

### Better compatibility with line search and trust regions

A merit function is the natural bridge to:

- Armijo or Wolfe line searches,
- trust-region acceptance tests,
- adaptive regularization,
- and later sparse or block-structured Newton-Krylov controllers.

Without a merit function, those methods have to borrow an acceptance rule from somewhere else. With a merit function, they all speak the same language.

### Cleaner diagnostics

A merit-based controller would also make ASTRA's diagnostics more interpretable:

- raw residual norms would remain scientific diagnostics,
- weighted residual norms would remain controller diagnostics,
- and the merit decrease would become the clean record of what the globalization layer believed it was optimizing.

## Why ASTRA is not implementing full merit globalization yet

The long-term direction is clear, but ASTRA is intentionally not landing the full method in this slice.

That is because a merit-based controller only helps if a few lower-level pieces are already trustworthy:

- the packed basis must be stable,
- the row weighting policy must be defensible,
- the correction metrics must not hide obvious pathologies,
- and the Jacobian must be good enough that predicted decrease means something.

ASTRA is not fully there yet. The weighted-metrics slice is therefore the right immediate move:

- it hardens the current controller,
- it makes solver metrics explicit,
- it gives the docs and tests a stable local contract,
- and it prepares the architecture for a later merit-function upgrade without widening the public ownership model.

## What is deferred

This page does **not** claim that ASTRA already has:

- a full merit-function line search,
- a trust-region controller,
- adaptive regularization based on predicted/actual reduction,
- or production-grade weighting policies for all future formulations.

Those are still future work.

## Implementation checklist

- [x] The page distinguishes physical residual meaning from solver metrics.
- [x] The current row-weight and correction-weight policies are stated explicitly.
- [x] The current correction limiter is defined as a solver-side envelope, not as a change in physics ownership.
- [x] The page explains why luminosity receives special treatment while remaining linear in `erg/s`.

## Validation checklist

- [x] The current ASTRA policy is described in terms that match the implemented weighted metrics.
- [x] The page names the raw-residual safeguard added after the first weighted-only attempt proved too permissive.
- [x] The file-backed MESA comparison is linked to the dedicated reference page rather than restated from memory.
- [ ] The weighting policy still needs broader benchmark evidence beyond the current toy-problem family.

## Open-risk checklist

- [x] The page says clearly that full merit-based globalization is still deferred.
- [x] The page treats the weighted-metrics slice as a precursor rather than as the final nonlinear controller.
- [ ] The future merit function still needs predicted-versus-actual decrease diagnostics before ASTRA should claim a mature globalization strategy.
