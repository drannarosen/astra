# Equation of State

The equation of state, or EOS, is the local rule that tells ASTRA how a parcel of stellar matter pushes back when it is compressed or heated. If you are new to stellar structure, this is one of the first places where the physics stops being just geometry and force balance and starts becoming matter-specific. The hydrostatic equation says what pressure gradient the star needs. The EOS says what pressure the material can actually provide.

In ASTRA's current bootstrap lane, the EOS is deliberately analytical. That is a feature, not a weakness. It means a new research student can read the equations, find the corresponding code, and understand exactly which thermodynamic assumptions are active before table-backed EOS machinery arrives. The active default is still an analytical gas plus radiation closure.

## Why the EOS matters

The EOS touches several parts of the stellar-structure problem at once:

- it sets the pressure used in hydrostatic balance,
- it helps determine the radiative temperature gradient through the pressure term,
- it provides the thermodynamic response coefficients used by the gravothermal term,
- and it controls how strongly the star reacts to compression and heating.

So the EOS is not just a way to get one number called `P`. It is a local thermodynamic model that tells the solver how matter responds when the nonlinear iteration changes `rho` and `T`.

## Current ASTRA implementation

ASTRA currently uses a staged analytical gas-plus-radiation EOS. In its default branch, the pressure is

$$
P = P_\mathrm{gas} + P_\mathrm{rad}
$$

with

$$
P_\mathrm{gas} = \frac{\rho k_B T}{\mu m_\mathrm{H}},
\qquad
P_\mathrm{rad} = \frac{a T^4}{3}.
$$

Here:

- $\rho$ is density in $\mathrm{g\,cm^{-3}}$,
- $T$ is temperature in K,
- $k_B$ is Boltzmann's constant,
- $a$ is the radiation constant,
- $m_\mathrm{H}$ is the hydrogen-mass constant used in ASTRA,
- $\mu$ is the mean molecular weight inferred from composition.

ASTRA's present composition model uses hydrogen, helium, and metals as bulk mass fractions, so the fully ionized mean molecular weight is

$$
\mu^{-1} = 2X + \frac{3}{4}Y + \frac{1}{2}Z.
$$

That formula already encodes an important stellar-physics idea: a fully ionized gas with more free particles per unit mass gives more pressure at fixed $\rho$ and $T$.

### Physical interpretation

This EOS is a good first teaching model because each term has a clear job.

- The gas term is the pressure of ions and electrons moving thermally.
- The radiation term is the momentum flux carried by the trapped photon field.
- The relative importance of those two pieces tells us how compressible the material is and how sensitive the star is to heating.

At modest temperatures and densities, gas pressure dominates and the star behaves roughly like a compressible plasma. At very high temperatures, radiation pressure becomes more important, and the thermodynamic response changes in ways that matter for transport and stability.

### Thermodynamic response quantities ASTRA uses

ASTRA's EOS does not stop at pressure. The active closure also returns:

- gas-pressure fraction `beta`,
- adiabatic gradient `adiabatic_gradient`,
- specific heat at constant pressure `specific_heat_erg_g_k`,
- thermodynamic response coefficients `chi_rho` and `chi_T`.

The gas-pressure fraction is

$$
\beta \equiv \frac{P_\mathrm{gas}}{P}.
$$

The response coefficients are defined by

$$
\chi_\rho \equiv \left(\frac{\partial \ln P}{\partial \ln \rho}\right)_T,
\qquad
\chi_T \equiv \left(\frac{\partial \ln P}{\partial \ln T}\right)_\rho.
$$

In the default gas-plus-radiation branch, ASTRA computes them from explicit pressure derivatives:

$$
\frac{\partial P}{\partial T}
= \frac{\rho k_B}{\mu m_\mathrm{H}} + \frac{4 a T^3}{3},
\qquad
\frac{\partial P}{\partial \rho}
= \frac{k_B T}{\mu m_\mathrm{H}},
$$

and then forms

$$
\chi_\rho = \frac{\rho}{P}\frac{\partial P}{\partial \rho},
\qquad
\chi_T = \frac{T}{P}\frac{\partial P}{\partial T}.
$$

The specific heat and adiabatic gradient are then built from the same thermodynamic state. In code, ASTRA first computes

$$
c_V =
\frac{3}{2}\frac{k_B}{\mu m_\mathrm{H}}
+
\frac{4 a T^3}{\rho},
$$

then promotes that to

$$
c_P
=
c_V + \frac{P \chi_T^2}{\rho T \chi_\rho},
$$

and finally computes

$$
\nabla_\mathrm{ad}
=
\frac{P \chi_T}{\rho T c_P \chi_\rho}.
$$

For a new student, the key point is that these are not decorative outputs. ASTRA uses them. The transport and gravothermal lanes depend on them directly.

### Flag-gated analytical enrichments

The same EOS object already carries two richer analytical corrections, both disabled in the default path:

1. `include_degeneracy = true`
   This replaces the ideal electron contribution with a Paczynski-style interpolation between ideal and non-relativistic degenerate electron pressure:
   $$
   P_e = \sqrt{P_{e,\mathrm{ideal}}^2 + P_{e,\mathrm{NR}}^2}.
   $$

2. `include_coulomb = true`
   This adds a negative Debye-Huckel-style Coulomb correction:
   $$
   P_\mathrm{coul} \propto - n_i k_B T \Gamma^{3/2}.
   $$

These terms are part of the current analytical microphysics stack, but ASTRA keeps them default-off because this bootstrap lane is still being validated. That is a recurring theme in the handbook: implemented does not automatically mean promoted.

## Numerical realization in ASTRA

ASTRA evaluates the EOS locally from the current cell state. Pressure is not a solve-owned variable. That means the nonlinear solve owns `log(r)`, `L`, `log(T)`, and `log(rho)`, while the EOS owns the map from `(rho, T, composition)` to thermodynamic quantities.

In practice:

- hydrostatic balance consumes EOS pressure,
- the transport helper consumes EOS pressure and `adiabatic_gradient`,
- the gravothermal helper consumes `specific_heat_erg_g_k`, `chi_rho`, and `chi_T`,
- the Jacobian consumes EOS pressure derivatives in packed-variable form.

The discrete realization is documented in [Residual Assembly](../methods/residual-assembly.md) and [Jacobian Construction](../methods/jacobian-construction.md). The exact staged formulas are collected in [Analytical Gas and Radiation EOS](eos/analytical-eos.md).

## What a richer EOS ecosystem would add later

ASTRA is intentionally not there yet, but a fuller stellar-physics ecosystem usually grows this lane in several directions:

- table-backed EOS packages,
- entropy-aware or inversion-aware thermodynamics,
- partial ionization and molecular chemistry,
- stronger degeneracy coverage,
- more complete Coulomb physics,
- explicit composition-sensitive thermodynamic derivatives across regime changes.

The richer local Stellax physics tree is a good example of that larger design space: it already contains EOS tables, inversion helpers, free-energy-based EOS work, and blended regime maps. ASTRA should eventually learn from that breadth, but the present page is about the analytical closure ASTRA actually uses now.

## What is deferred

Real EOS tables, partial ionization, entropy-authoritative inversion, and composition-rich thermodynamics are deferred. Degeneracy and Coulomb terms are implemented analytically but are not active in the default bootstrap lane yet. This page is the place to explain the closure ASTRA actually has now, not the closure we will want later.

## Internal QA

### Implementation checklist

- [x] The default gas-plus-radiation pressure law is stated explicitly.
- [x] The mean molecular weight formula used by the analytical branch is stated explicitly.
- [x] The page explains `beta`, `chi_rho`, `chi_T`, `c_P`, and `nabla_ad` at the level ASTRA actually uses them.
- [x] The page distinguishes default behavior from flag-gated degeneracy and Coulomb enrichments.
- [x] The page says clearly that pressure is EOS-owned state, not a solve-owned variable.

### Testing checklist

- [x] ASTRA has direct EOS regression tests for default and flagged analytical branches.
- [x] ASTRA has local derivative checks for `dP/dT` and `dP/drho`.
- [x] ASTRA has row-level tests that exercise EOS-dependent hydrostatic and transport behavior.
- [ ] A student-facing notebook or worked example still needs to be added for EOS sanity checks across representative core and envelope states.

### Validation checklist

- [ ] Pressure and derivative formulas are benchmarked against an independent reference for representative states.
- [ ] Degeneracy and Coulomb terms remain disabled until derivative validation justifies enabling them in the bootstrap lane.
- [ ] The staged analytical EOS should eventually be compared against a table-backed reference over a controlled stellar-state grid.

### Deferred-scope checklist

- [x] Real EOS tables are not yet in the active ASTRA solver lane.
- [x] Partial ionization and molecular thermodynamics are not yet modeled.
- [x] Entropy-authoritative inversion is not yet part of the active analytical closure.
- [x] Default-on promotion of degeneracy and Coulomb terms is intentionally deferred.
