# Analytical Nuclear Heating

This page is the equation-heavy companion to [Nuclear Energy Generation](../nuclear.md). The top-level page explains the physical role of nuclear heating. This page records the exact staged analytical formulas ASTRA currently uses.

## Temperature variables and smooth transitions

ASTRA expresses the analytical burning fits in the standard scaled temperatures

$$
T_6 = \frac{T}{10^6\ \mathrm{K}},
\qquad
T_9 = \frac{T}{10^9\ \mathrm{K}}.
$$

To keep the analytical closure differentiable across regime changes, ASTRA uses the smooth turn-on function

$$
s(x;x_0,w)
=
\frac{1}{2}\left[1+\tanh\!\left(\frac{x-x_0}{w}\right)\right].
$$

This means the low-temperature suppression of a branch is smooth rather than a hard on/off switch. For Newton and local derivative checks, that matters a lot.

## PP-chain heating

The analytical PP branch is

$$
\varepsilon_\mathrm{PP}
=
2.38\times10^6
\rho X^2
T_6^{-2/3}
\exp\!\left(-33.80\,T_6^{-1/3}\right)
g_{11}(T_6)
f_\mathrm{screen,PP}
s(T_6;4,1),
$$

where the correction factor is

$$
g_{11}(T_6)
=
1
+
0.0123\,T_6^{1/3}
+
0.0109\,T_6^{2/3}
+
9.38\times10^{-4} T_6.
$$

The most important physical lesson is the strong temperature sensitivity hidden in the exponential Gamow-like factor. Even the "gentle" PP chain is not actually weakly temperature dependent. It is only gentler than CNO.

## CNO-cycle heating

The analytical CNO branch is

$$
\varepsilon_\mathrm{CNO}
=
8.67\times10^{25}
\rho X Z_\mathrm{CNO}
T_6^{-2/3}
\exp\!\left(-152.28\,T_6^{-1/3}\right)
f_\mathrm{screen,CNO}
s(T_6;15,3),
$$

with

$$
Z_\mathrm{CNO} = 0.7\,Z.
$$

This is why CNO behaves like a sharper thermostat. The exponential barrier is far steeper, so once the temperature gets high enough, the reaction rate turns on much more aggressively than the PP chain.

## Triple-alpha heating

When `include_3alpha = true`, ASTRA adds

$$
\varepsilon_{3\alpha}
=
5.1\times10^8
\rho^2 Y^3
T_9^{-3}
\exp\!\left(-4.4/T_9\right)
s(T_9;0.1,0.03).
$$

This is default-off because ASTRA's present bootstrap lane is not yet an abundance-evolving helium-burning code. But the staged branch is present so the architecture already has an obvious place for that later physics.

## Weak-screening factor

If `include_screening = true`, ASTRA applies a weak-Salpeter-style screening factor to the PP and CNO branches.

The screening helper first estimates:

$$
n_e = \frac{\rho\,Y_e}{m_u},
\qquad
Y_e = \frac{1+X}{2},
$$

and an ion density

$$
n_i = \frac{\rho}{m_u}
\left(X + \frac{Y}{4} + \frac{Z}{16}\right).
$$

It then forms an average charge-squared proxy

$$
\overline{Z^2}
=
\frac{
X(1)^2 + \frac{Y}{4}(2)^2 + \frac{Z}{16}(8)^2
}{
X + \frac{Y}{4} + \frac{Z}{16}
}.
$$

From this, ASTRA builds a screening density,

$$
n_\mathrm{screen} = n_e + n_i \overline{Z^2},
$$

a Debye length

$$
\lambda_D
=
\sqrt{
\frac{k_B T}{4\pi n_\mathrm{screen} e^2}
},
$$

and the weak-screening exponent

$$
h_\mathrm{weak}
=
\frac{Z_i Z_j e^2}{k_B T\,\lambda_D}.
$$

The final screening factor is then regularized in three ways:

- the exponent is capped so the factor cannot grow without bound,
- a low-density tanh cutoff suppresses screening where it should be negligible,
- the final factor is clamped to the range `[1, 10]`.

That is why this should be read as a staged analytical weak-screening proxy rather than as a final screening package for all stellar regimes.

## Derivatives ASTRA uses

ASTRA tracks the literal payload names `dε/dT` and `dε/drho` because those are the source sensitivities the luminosity row consumes.

The current derivative helpers are explicit centered local finite differences through the analytical closure:

$$
\frac{d\varepsilon}{dT}
\approx
\frac{\varepsilon(\rho, T+\Delta T)-\varepsilon(\rho, T-\Delta T)}{2\Delta T},
$$

$$
\frac{d\varepsilon}{d\rho}
\approx
\frac{\varepsilon(\rho+\Delta\rho, T)-\varepsilon(\rho-\Delta\rho, T)}{2\Delta\rho}.
$$

This keeps derivative ownership inside the ASTRA bootstrap microphysics layer without adding automatic differentiation.

## How it enters ASTRA

The public nuclear closure returns only the scalar heating payload `energy_rate_erg_g_s`. The luminosity residual does not evolve abundances directly from this closure. Instead:

- the nuclear closure supplies `eps_nuc`,
- the energy-source helper combines it with `eps_grav` and `eps_nu`,
- the luminosity row consumes the assembled source term.

That ownership split is one of the most important architectural lessons in this part of the codebase. The row-level realization is documented in [Residual Assembly](../../methods/residual-assembly.md).

## What is deferred

Real reaction networks, composition evolution, and detailed screening physics are deferred. Screening and triple-alpha remain flag-gated in the default path. Neutrino losses are not owned by this closure; they live in the broader analytical energy-source helper lane. This page documents the bootstrap heating source ASTRA actually uses today, not a full abundance-evolution or reaction-network package.
