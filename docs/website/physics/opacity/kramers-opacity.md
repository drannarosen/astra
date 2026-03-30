# Kramers Opacity

ASTRA's current opacity is a smooth Kramers-like stand-in for a Rosseland mean opacity. It is deliberately simple so the transport row and its derivatives stay explicit during bootstrap.

## Current formula

The current closure is

$$
\kappa(\rho, T, X, Y) = 4.0 \times 10^{25} \, \max(Z, 10^{-3}) \, \rho \, T^{-3.5}
$$

where `Z` is the metallicity implied by composition. This is the current analytic opacity law in `src/microphysics/opacity.jl`.

The page mentions `Rosseland` because the transport equation ultimately wants a Rosseland mean opacity, but ASTRA's present implementation is this toy Kramers law, not a table-backed Rosseland stack.

## Derivatives ASTRA uses

The Jacobian and transport helper use the opacity derivative payloads

ASTRA tracks the literal payload names `dκ/dT` and `dκ/drho` here so the derivative story matches the code-facing terminology.

$$
\frac{d\kappa}{dT} = -3.5 \, \frac{\kappa}{T}
$$

$$
\frac{d\kappa}{d\rho} = 4.0 \times 10^{25} \, \max(Z, 10^{-3}) \, T^{-3.5}
$$

These are the `opacity_temperature_derivative(...)` and `opacity_density_derivative(...)` helpers in `src/microphysics/opacity.jl`.

## How it enters ASTRA

Opacity feeds the radiative-gradient helper in `src/structure_equations.jl`. That helper multiplies opacity, luminosity, pressure, and the local geometric factors to produce the transport gradient used by the residual. The local derivatives matter because the Jacobian audit checks the same helper in density and temperature directions.

## What is deferred

Real Rosseland tables, low-temperature molecular physics, conductive opacity, and blend hierarchies are deferred. This is the current placeholder opacity law, not a production opacity subsystem.
