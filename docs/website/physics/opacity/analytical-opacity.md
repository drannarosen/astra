# Analytical Opacity Components

This page is the equation-heavy companion to [Opacity](../opacity.md). The top-level page explains why opacity matters. This page records the exact staged analytical opacity formulas ASTRA currently uses.

## Structure of the closure

ASTRA's current opacity is a staged analytical Rosseland-mean proxy built from three additive components:

$$
\kappa = \kappa_\mathrm{Kramers} + \kappa_{H^-} + \kappa_\mathrm{es}.
$$

The page mentions `Rosseland` because the transport equation ultimately wants a Rosseland mean opacity, but ASTRA's present implementation is still an analytical stand-in rather than a table-backed Rosseland stack.

## Kramers component

The Kramers-like term in ASTRA is

$$
\kappa_\mathrm{Kramers}
=
4.34\times 10^{25}
\left[\frac{Z_\mathrm{eff}(1+X)}{2}\right]
\rho T^{-3.5}\,\bar g(T),
$$

where the effective metallicity is

$$
Z_\mathrm{eff} = \max(Z, 10^{-3}),
$$

and the Rosseland-mean Gaunt-factor proxy is

$$
\bar g(T)
=
\max\!\left(
1,\;
1.226 + 0.0426x - 0.0157x^2 + 0.00243x^3
\right),
$$

with

$$
x = \log_{10}(T) - 4.
$$

The physical picture is straightforward:

- opacity increases with density because there are more absorbers,
- opacity falls steeply with temperature because hotter gas is more ionized and more transparent to these absorption processes,
- the Gaunt-factor term slightly reshapes the simple power law.

## H-minus component

ASTRA's H-minus term is a simplified proxy rather than a full atmosphere-grade H-minus package. It is built from a bound-free piece plus a free-free piece.

First the code constructs a gas pressure

$$
P_\mathrm{gas}
=
\frac{\rho k_B T}{\mu m_\mathrm{H}},
$$

an electron-pressure proxy

$$
P_e = P_\mathrm{gas}\left(\frac{\mu}{\mu_e}\right),
$$

and a hydrogen pressure

$$
P_H = \frac{X \rho k_B T}{m_\mathrm{H}}.
$$

The ionization factor is

$$
f_\mathrm{ion}
=
\exp\!\left(\frac{T_\mathrm{ion}}{T}\right)
\left(1 + 0.035\sqrt{T} - 4.3\times 10^{-4}T\right),
$$

with the exponent clipped internally for numerical safety and

$$
T_\mathrm{ion} \approx 0.754 \times 11605\ \mathrm{K}.
$$

The bound-free and free-free pieces are then

$$
\kappa_{H^-,\mathrm{bf}}
=
1.1\times10^{-25} P_e T^{-4.5} f_\mathrm{ion},
$$

$$
\kappa_{H^-,\mathrm{ff}}
=
3.7\times10^{-38} P_e P_H T^{-3.5}.
$$

ASTRA multiplies their sum by a smooth temperature window

$$
w(T) = w_\mathrm{on}(T)\,w_\mathrm{off}(T),
$$

with

$$
w_\mathrm{on}
=
\frac{1}{2}\left[1+\tanh\!\left(\frac{\log_{10}T-\log_{10}(4000)}{0.2}\right)\right],
$$

$$
w_\mathrm{off}
=
\frac{1}{2}\left[1+\tanh\!\left(\frac{\log_{10}(15000)-\log_{10}T}{0.3}\right)\right].
$$

So the final staged H-minus opacity is

$$
\kappa_{H^-}
=
w(T)\left(\kappa_{H^-,\mathrm{bf}} + \kappa_{H^-,\mathrm{ff}}\right).
$$

Pedagogically, the important thing is not to memorize the coefficients. It is to notice the design logic: ASTRA activates this mechanism only in the cool regime where it makes physical sense.

## Electron-scattering component

The electron-scattering term is

$$
\kappa_\mathrm{es}
=
0.2(1+X)\,f_\mathrm{KN},
$$

with the current Klein-Nishina-style correction

$$
f_\mathrm{KN}
=
\frac{1}{1+\theta^{0.86}},
\qquad
\theta = \frac{k_B T}{m_e c^2}.
$$

In the low-energy Thomson limit, this reduces to the familiar composition-controlled scattering opacity. At higher thermal energies, the correction softens that limit.

## Why ASTRA sums these terms

ASTRA adds the three components arithmetically:

$$
\kappa = \kappa_\mathrm{Kramers} + \kappa_{H^-} + \kappa_\mathrm{es}.
$$

That is a staged modeling choice, not a claim that this is the final opacity architecture for all stellar regimes. It works reasonably well as a bootstrap analytical closure because the three mechanisms tend to dominate in different parts of state space, making the sum a transparent first approximation.

## Derivatives ASTRA uses

The Jacobian and transport helper use the opacity derivative payloads `dκ/dT` and `dκ/drho`.

ASTRA currently evaluates them through explicit centered local finite differences:

$$
\frac{d\kappa}{dT}
\approx
\frac{\kappa(\rho, T+\Delta T)-\kappa(\rho, T-\Delta T)}{2\Delta T},
$$

$$
\frac{d\kappa}{d\rho}
\approx
\frac{\kappa(\rho+\Delta \rho, T)-\kappa(\rho-\Delta \rho, T)}{2\Delta \rho}.
$$

This keeps the derivative owner local without introducing a new AD dependency in the bootstrap lane. It also means ASTRA differentiates the exact smoothed analytical opacity it solves with, including the H-minus windowing.

## How it enters ASTRA

Opacity feeds the radiative-gradient helper in `src/numerics/structure_equations.jl`. That helper combines opacity, luminosity, pressure, enclosed mass, and temperature to produce the transport gradient used in the residual. The local opacity derivatives matter because the Jacobian audit checks how that transport helper responds to density and temperature perturbations.

The discrete method-side realization is documented in [Residual Assembly](../../methods/residual-assembly.md), and the current derivative path is summarized in [Jacobian Construction](../../methods/jacobian-construction.md).

## What is deferred

Real Rosseland tables, conductive opacity, and blend hierarchies are deferred. The H-minus term is still a simplified analytical proxy, not a production low-temperature opacity subsystem.
