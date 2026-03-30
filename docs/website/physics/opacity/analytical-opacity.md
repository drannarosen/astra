# Analytical Opacity Components

ASTRA's current opacity is a staged analytical Rosseland-mean proxy built from three components. It is still deliberately explicit so the transport row and its derivatives stay inspectable during bootstrap.

## Current formula

The current closure is the arithmetic sum of:

- Kramers bound-free/free-free opacity with a Gaunt-factor correction,
- H-minus bound-free plus free-free opacity in the `4000-15000 K` window,
- electron scattering with a Klein-Nishina correction.

The page mentions `Rosseland` because the transport equation ultimately wants a Rosseland mean opacity, but ASTRA's present implementation is still an analytical stand-in rather than a table-backed Rosseland stack.

## Derivatives ASTRA uses

The Jacobian and transport helper use the opacity derivative payloads

ASTRA tracks the literal payload names `dκ/dT` and `dκ/drho` here so the derivative story matches the code-facing terminology.

The current `opacity_temperature_derivative(...)` and `opacity_density_derivative(...)` helpers in `src/microphysics/opacity.jl` are explicit ASTRA-owned centered local finite differences through this analytical closure. That keeps the derivative owner local without introducing a new AD dependency in the bootstrap lane.

## How it enters ASTRA

Opacity feeds the radiative-gradient helper in `src/numerics/structure_equations.jl`. That helper multiplies opacity, luminosity, pressure, and the local geometric factors to produce the transport gradient used by the residual. The local derivatives matter because the Jacobian audit checks the same helper in density and temperature directions.

The discrete method-side realization is documented in [Residual Assembly](../../methods/residual-assembly.md), and the current derivative path is summarized in [Jacobian Construction](../../methods/jacobian-construction.md).

## What is deferred

Real Rosseland tables, conductive opacity, and blend hierarchies are deferred. The H-minus term is still a simplified analytical proxy, not a production low-temperature opacity subsystem.
