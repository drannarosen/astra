# Nuclear Energy Generation

Nuclear heating is the part of stellar microphysics that tells ASTRA how local reactions add energy to the star. For a new student, this is often the most intuitive physics page because it feels closest to the basic story of stars: hydrogen burns, helium builds up, and the released energy helps power the luminosity. In the present ASTRA lane, that story is implemented as a staged analytical PP-plus-CNO heating closure with optional richer branches.

But in a structure code, nuclear physics is not just a story about where starlight comes from. It is a local source term that enters the luminosity equation and changes the global nonlinear solution.

## Why nuclear heating matters

The classical luminosity equation is

$$
\frac{dL}{dm} = \varepsilon_\mathrm{nuc} + \varepsilon_\mathrm{grav} - \varepsilon_\nu.
$$

So `eps_nuc` is only one part of the energy budget. Even so, it is usually the most conceptually central term because it is the part tied directly to composition and burning regime.

In ASTRA's current analytical lane:

- the nuclear closure owns `eps_nuc`,
- the energy-source helper assembles `eps_nuc + eps_grav - eps_nu`,
- composition evolution is still deferred,
- and the point of the present closure is to provide a realistic-enough source law with smooth derivatives.

## Current ASTRA implementation

ASTRA currently uses a staged analytical nuclear-heating closure with

$$
\varepsilon_\mathrm{nuc}
=
\varepsilon_\mathrm{PP}
+
\varepsilon_\mathrm{CNO}
+
\varepsilon_{3\alpha},
$$

where the triple-alpha term is present in code but disabled by default.

The default public configuration therefore means:

- PP-chain heating is active,
- CNO-cycle heating is active,
- triple-alpha is compiled in but default-off,
- weak screening is available but default-off.

### Physical interpretation

This is a useful teaching model because each burning branch has a distinct personality.

- PP burning is the gentler hydrogen-burning channel that can matter at lower core temperatures.
- CNO burning is far more temperature-sensitive and acts like a sharper thermostat once the core is hot enough.
- Triple-alpha is helium burning and therefore belongs to a later evolutionary regime than the default ASTRA bootstrap lane.

The closure does not yet evolve composition. That means ASTRA currently asks, "How much heat would this composition produce at this local state?" but not yet, "How does the composition itself change in time because of these reactions?"

### Exact staged formulas

ASTRA evaluates the PP and CNO branches with analytical Kippenhahn-and-Weigert-style parameterizations, using temperature units

$$
T_6 = \frac{T}{10^6\ \mathrm{K}},
\qquad
T_9 = \frac{T}{10^9\ \mathrm{K}}.
$$

It also uses smooth turn-on functions so the regime transitions remain differentiable:

$$
s(x;x_0,w)
=
\frac{1}{2}\left[1+\tanh\!\left(\frac{x-x_0}{w}\right)\right].
$$

The top-level forms are:

$$
\varepsilon_\mathrm{PP}
\propto
\rho X^2 T_6^{-2/3}
\exp\!\left(-33.80\,T_6^{-1/3}\right)
g_{11}(T_6)\,
f_\mathrm{screen,PP}\,
s(T_6;4,1),
$$

$$
\varepsilon_\mathrm{CNO}
\propto
\rho X Z_\mathrm{CNO} T_6^{-2/3}
\exp\!\left(-152.28\,T_6^{-1/3}\right)
f_\mathrm{screen,CNO}\,
s(T_6;15,3),
$$

$$
\varepsilon_{3\alpha}
\propto
\rho^2 Y^3 T_9^{-3}
\exp\!\left(-4.4/T_9\right)
s(T_9;0.1,0.03).
$$

The exact staged coefficients and screening proxy are collected in [Analytical Nuclear Heating](nuclear/analytical-burning.md).

### Weak screening in the current analytical lane

If `include_screening = true`, ASTRA applies a weak-Salpeter-style enhancement factor to the PP and CNO branches. This is important to explain carefully.

- Screening is implemented.
- Screening is not default-on.
- Screening is still weak-screening only.
- Screening is still a staged analytical proxy, not a full strong-screening or network-aware package.

That is the kind of distinction new students need to learn early: "implemented" is not the same thing as "scientifically complete."

### What the public closure returns

The present public closure payload is intentionally narrow:

- `energy_rate_erg_g_s`
- `source = :analytical_nuclear`

That means ASTRA currently owns nuclear heating without widening the public microphysics contract into abundance evolution. The richer local Stellax ecosystem already shows what comes next in a fuller codebase: reaction networks, derived rates, screening modules, weak rates, REACLIB machinery, and abundance time derivatives. ASTRA is not there yet, and the docs should say so plainly.

## Numerical realization in ASTRA

The luminosity row in [Residual Assembly](../methods/residual-assembly.md) consumes a source-decomposed helper payload. So the analytical nuclear closure feeds the `eps_nuc` contribution inside a row that also owns `eps_grav` and `eps_nu`.

This is worth emphasizing for students because it teaches ownership correctly:

- the nuclear closure does **not** own the whole luminosity equation,
- it owns the nuclear heating contribution,
- the residual helper owns the final source assembly.

The Jacobian audit in [Jacobian Construction](../methods/jacobian-construction.md) checks the local density and temperature derivatives that this closure contributes to that combined energy-source lane.

## What a richer nuclear ecosystem would add later

The analytical closure is only the first rung of the ladder. A fuller stellar-nuclear ecosystem often adds:

- reaction networks,
- abundance time derivatives,
- weak rates and neutrino-linked processes,
- stronger screening regimes,
- tabulated or REACLIB-style reaction libraries,
- equilibrium and NSE tools for hotter regimes,
- validation artifacts against network or benchmark calculations.

The local Stellax physics tree already contains many of those components. That is helpful as a migration map. But ASTRA's present page should teach the analytical closure ASTRA actually uses now.

## What is deferred

Real reaction networks, intermediate/strong screening physics, and composition evolution are deferred. Triple-alpha and screening remain flag-gated rather than default-on. This page documents the current heating closure that ASTRA actually uses inside the broader energy-source lane, not a full reaction network or abundance-evolution package.

## Internal QA

### Implementation checklist

- [x] The active analytical nuclear source is stated explicitly as PP + CNO + optional `3alpha`.
- [x] The page explains the physical role of PP, CNO, and triple-alpha in student-facing language.
- [x] The page states that screening is implemented as a weak, flag-gated enhancement.
- [x] The page states clearly that composition evolution is still outside the public closure payload.
- [x] The page points to the source-decomposed luminosity-row owner rather than implying the nuclear closure owns the full energy equation.

### Testing checklist

- [x] ASTRA has direct analytical nuclear regression tests for the staged branches.
- [x] ASTRA has local derivative validation for `dε/dT` and `dε/drho`.
- [x] ASTRA has row-level tests that exercise nuclear-source participation in the luminosity equation.
- [ ] A student-facing worked example comparing PP-dominated and CNO-dominated regimes is still missing.

### Validation checklist

- [ ] The source term and its derivatives are benchmarked against a reference artifact or regression envelope.
- [ ] The weak-screening enhancement should eventually be compared against a trusted screening reference across representative states.
- [ ] The transition from analytical heating to a richer source model should be documented with an explicit parity or validation plan.

### Deferred-scope checklist

- [x] Composition evolution is not yet part of the active ASTRA nuclear closure.
- [x] REACLIB-style or network-based burning is not yet in the active ASTRA solver lane.
- [x] Intermediate and strong screening are deferred.
- [x] Default-on promotion of screening and triple-alpha is intentionally deferred.
