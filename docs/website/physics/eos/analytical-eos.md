# Analytical Gas and Radiation EOS

This page is the equation-heavy companion to [Equation of State](../eos.md). The top-level page explains why the EOS matters. This page records the exact staged formulas ASTRA currently uses in the analytical EOS lane.

## State variables and composition model

The analytical EOS closure is called in linear cgs variables:

$$
(\rho,\; T,\; X,\; Y,\; Z).
$$

Here:

- $\rho$ is density in $\mathrm{g\,cm^{-3}}$,
- $T$ is temperature in K,
- $X$, $Y$, and $Z$ are hydrogen, helium, and metal mass fractions.

ASTRA assumes a fully ionized bulk composition in the active analytical EOS branch. The mean molecular weights used in code are:

$$
\mu^{-1} = 2X + \frac{3}{4}Y + \frac{1}{2}Z,
$$

$$
\mu_e = \frac{2}{1+X},
$$

$$
\mu_I^{-1} = X + \frac{1}{4}Y + \frac{1}{16}Z.
$$

The first is the overall mean molecular weight, the second is the mean molecular weight per electron, and the third is the mean molecular weight per ion. Even if you never memorize these, it is worth learning what they mean physically: composition changes the number of particles and therefore changes pressure and heat capacity at fixed density and temperature.

## Default pressure decomposition

ASTRA's default pressure decomposition is

$$
P = P_\mathrm{gas} + P_\mathrm{rad}.
$$

The gas term is

$$
P_\mathrm{gas}
=
\frac{\rho k_B T}{\mu m_\mathrm{H}},
$$

and the radiation term is

$$
P_\mathrm{rad}
=
\frac{aT^4}{3}.
$$

In code, ASTRA computes pressure in slightly more resolved form:

$$
P_\mathrm{gas} = P_\mathrm{ions} + P_e,
$$

with

$$
P_\mathrm{ions}
=
P_{\mathrm{gas,ideal}} - P_{e,\mathrm{ideal}},
$$

so the flagged degeneracy branch can swap in a richer electron term without rewriting the ion term.

## Flag-gated degeneracy correction

When `include_degeneracy = true`, ASTRA replaces the ideal electron pressure with the Paczynski-style interpolation

$$
P_e = \sqrt{P_{e,\mathrm{ideal}}^2 + P_{e,\mathrm{NR}}^2}.
$$

The ideal electron pressure is

$$
P_{e,\mathrm{ideal}} = \frac{\rho k_B T}{\mu_e m_\mathrm{H}},
$$

and the non-relativistic degenerate term is

$$
P_{e,\mathrm{NR}} = K_\mathrm{NR} n_e^{5/3},
$$

with

$$
n_e = \frac{\rho}{\mu_e m_u},
\qquad
K_\mathrm{NR}
=
\frac{\hbar^2}{5m_e}(3\pi^2)^{2/3}.
$$

This is not yet a full production degenerate EOS. It is an analytical interpolation that lets ASTRA explore the right direction of the physics while preserving explicit local ownership.

## Flag-gated Coulomb correction

When `include_coulomb = true`, ASTRA adds a Debye-Huckel-style correction

$$
P_\mathrm{coul}
=
-A_\mathrm{DH}\, n_i k_B T\, \Gamma^{3/2},
$$

where

$$
n_i = \frac{\rho}{\mu_I m_u},
\qquad
a_i = \left(\frac{3}{4\pi n_i}\right)^{1/3},
$$

$$
\Gamma
=
\frac{\langle Z^2 \rangle e^2}{a_i k_B T}.
$$

In the present H/He/Z bulk-composition approximation, ASTRA uses

$$
\langle Z^2 \rangle \approx 1 + 3Y,
\qquad
A_\mathrm{DH} = \frac{\sqrt{3}}{2}.
$$

This term is negative because Coulomb attraction lowers the pressure relative to an ideal gas. Again, that is the right physical direction, but it is still a staged analytical correction rather than a parity-grade EOS.

## Pressure derivatives and thermodynamic response

ASTRA tracks the literal payload names `dP/dT` and `dP/drho` because those are the sensitivities future developers search for first.

In the default gas-plus-radiation branch:

$$
\frac{dP}{dT}
=
\frac{\rho k_B}{\mu m_\mathrm{H}}
+
\frac{4aT^3}{3},
$$

$$
\frac{dP}{d\rho}
=
\frac{k_B T}{\mu m_\mathrm{H}}.
$$

In the flagged branches, ASTRA does not try to hand-maintain all thermodynamic derivatives analytically. Instead it computes `dP/dT` and `dP/drho` through explicit centered local finite differences of the staged pressure state. That is a deliberate ownership choice: explicit local derivatives, but no new AD dependency in ASTRA.

From those derivatives, ASTRA constructs

$$
\chi_\rho = \frac{\rho}{P}\frac{dP}{d\rho},
\qquad
\chi_T = \frac{T}{P}\frac{dP}{dT}.
$$

For the default gas-plus-radiation branch, these reduce to the familiar beta-based values. For flagged degeneracy or Coulomb branches, ASTRA uses the EOS-returned `chi_rho` and `chi_T` directly. That matters because the gravothermal lane should follow the actual staged thermodynamic response, not an idealized identity that may no longer hold.

## Specific heat and adiabatic gradient

ASTRA computes the constant-volume specific heat as

$$
c_V
=
\frac{3}{2}\frac{k_B}{\mu m_\mathrm{H}}
+
\frac{4aT^3}{\rho}.
$$

It then promotes this to

$$
c_P
=
c_V + \frac{P\chi_T^2}{\rho T \chi_\rho},
$$

and uses that to compute

$$
\nabla_\mathrm{ad}
=
\frac{P\chi_T}{\rho T c_P \chi_\rho}.
$$

These formulas are thermodynamic identities expressed in the response variables ASTRA already owns. They are especially important because `specific_heat_erg_g_k`, `chi_rho`, `chi_T`, and the payload `adiabatic_gradient` are not abstract outputs. They feed directly into the gravothermal and transport lanes.

## Implementation notes

- ASTRA evaluates the EOS in linear cgs variables and returns a narrow payload.
- Pressure is derived from state, not stored as an independent solve variable.
- In the flagged branches, a small positivity floor protects intermediate Newton states from unphysical negative total pressure when the Coulomb correction temporarily overwhelms the trial-state gas-plus-radiation pressure.
- The exact code owner is `src/microphysics/eos.jl`.

## How it enters ASTRA

The EOS pressure is used directly in the hydrostatic row and in the radiative transport helper. The EOS thermodynamic response terms also feed the gravothermal source lane, which is why `chi_rho` and `chi_T` are first-class outputs in the current analytical closure.

The discrete implementation details live in [Residual Assembly](../../methods/residual-assembly.md) and [Jacobian Construction](../../methods/jacobian-construction.md).

## What is deferred

Real EOS tables, partial ionization, entropy-authoritative inversion, and composition-rich thermodynamics are deferred. Degeneracy and Coulomb corrections remain flag-gated in the default path. This page documents the staged analytical closure ASTRA actually solves with today, not the closure a production stellar model would ultimately need.
