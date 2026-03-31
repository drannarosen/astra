# Convection

Convection is the part of stellar physics that decides when radiative diffusion stops being the correct transport branch and buoyant motion must carry part of the flux instead. In classical stellar structure, that story has three distinct layers:

- an instability criterion that decides whether a stratification is stable or unstable,
- a transport closure that supplies the active temperature gradient in unstable zones,
- and a mixing model that says what convection does to composition.

ASTRA's current bootstrap lane now owns the first two layers in code. The documentation in this section therefore has to do two jobs at once: say plainly what ASTRA computes today, and lock in the physically correct target that the remaining convection extensions must obey.

## Transport language and symbols

Throughout ASTRA's physics and methods pages, the dimensionless temperature gradient is

$$
\nabla \equiv \frac{d \ln T}{d \ln P}.
$$

That symbol means the **active** transport gradient, not automatically the radiative one. The other gradients used in convection work are:

- $\nabla_\mathrm{rad}$: the radiative candidate supplied by diffusion,
- $\nabla_\mathrm{ad}$: the adiabatic gradient supplied by the EOS,
- $\nabla_\mu \equiv d \ln \mu / d \ln P$: the composition-gradient term needed for Ledoux-ready design,
- $\nabla_\mathrm{L}$: the Ledoux critical gradient,
- $\nabla_\mathrm{conv}$: the convective-branch gradient returned by the convective closure in unstable cells.

That distinction matters because one of ASTRA's current scientific gaps is precisely that the residual still treats $\nabla$ as if it were always equal to $\nabla_\mathrm{rad}$.

## Current status vs target model

The current code-backed fact is now broader:

- ASTRA computes $\nabla_\mathrm{rad}$,
- ASTRA computes $\nabla_\mathrm{ad}$ from the EOS,
- ASTRA applies a Schwarzschild criterion hook,
- and the active residual now uses Bohm-Vitense local MLT rather than a radiative-only transport law.

The near-term canonical target is now the implementation target for the remaining convection growth:

- the active transport gradient must be branch-owned,
- stable cells should use $\nabla = \nabla_\mathrm{rad}$,
- unstable cells should use the branch-owned convective closure,
- and ASTRA's first serious convective closure is **Bohm-Vitense local MLT**, with Schwarzschild-active branch selection at first and a **Ledoux-ready** interface from day one.

The later target is broader still:

- Ledoux-active transport when composition gradients matter,
- convective mixing as a distinct subsystem,
- and later surface-loss, overshoot, semiconvective, thermohaline, and turbulent-pressure extensions when the classical baseline is trustworthy enough to justify them.

## Current ASTRA implementation

Today ASTRA owns a **Schwarzschild criterion hook plus Bohm-Vitense local MLT in the active transport residual**. In plain language, ASTRA can already ask, "Would radiation alone carry the flux stably here?" and, if not, it now uses the convective transport law to set the actual temperature gradient.

That means the current solver is still physically incomplete, but in a narrower way than before. The instability logic already exists, the transport row now switches to the convective branch, and the remaining missing physics lives in Ledoux-active transport, composition mixing, and later nonlocal or surface-loss refinements.
The old radiative-only transport lane is now historical.

## Numerical realization in ASTRA

The current instability hook and its radiative-gradient helper are summarized in [Radiative Gradient, Schwarzschild, and Ledoux Readiness](convection/radiative-gradient-and-criterion-hook.md). The now-implemented transport closure is summarized separately in [Mixing-Length Theory Target](convection/mixing-length-theory.md).

The residual owner remains the transport row in [Residual Assembly](../methods/residual-assembly.md), and the derivative story for the current helper lane is tracked in [Jacobian Construction](../methods/jacobian-construction.md). Those methods pages should be read with one caution in mind: the current row is numerically real, but it is not yet the canonical physical transport law ASTRA intends to keep.

## What is deferred

The first canonical ASTRA convection implementation includes local MLT transport, but it should not pretend to solve every convection problem at once. The following items remain deferred beyond that first transport cutover:

- overshoot,
- semiconvection,
- thermohaline transport,
- turbulent pressure,
- time-dependent convection,
- and composition mixing as an active evolution operator.

This page therefore distinguishes three things explicitly:

- code-backed fact: the transport residual is now branch-owned and uses Bohm-Vitense local MLT, while the criterion lane remains Schwarzschild-active and Ledoux-ready,
- canonical target: branch-owned transport with Bohm-Vitense local MLT for the active residual,
- deferred physics: richer convection and mixing modules that should not be smuggled into the first trustworthy baseline.

## Implementation checklist

- [x] The page separates instability criteria, transport closure, and convective mixing.
- [x] The page states that Bohm-Vitense local MLT is now implemented in the active residual.
- [x] The page names Bohm-Vitense local MLT as the canonical first closure.
- [x] The page states explicitly that the architecture is Ledoux-ready even before Ledoux is active.
- [x] The future code path has now locked the exact local MLT normalization and solver interface in implementation.

## Deferred-scope checklist

- [x] Real local MLT is implemented in the active residual.
- [x] Ledoux-active transport is not implemented yet.
- [x] Convective composition mixing is not implemented yet.
- [x] Overshoot, semiconvection, thermohaline transport, and turbulent pressure are not implemented.
- [x] The transport residual has been updated to replace the radiative-only assumption explicitly.
