# Ideal Gas Plus Radiation EOS

ASTRA's current EOS is a pressure decomposition, not a table lookup: gas pressure plus radiation pressure, with smooth analytic derivatives for the Newton solve.

## Current formula

The current closure is

$$
P(\rho, T, X, Y) = \frac{\rho k_B T}{\mu m_u} + \frac{a T^4}{3}
$$

where `rho` is density, `T` is temperature, `mu` is the mean molecular weight from composition, `m_u` is the hydrogen mass constant used in ASTRA, `k_B` is Boltzmann's constant, and `a` is the radiation constant.

This is the exact pressure decomposition ASTRA uses today in `src/microphysics/eos.jl`.

## Derivatives ASTRA uses

The EOS provides the derivative payloads the Jacobian and transport helper need:

ASTRA tracks the literal payload names `dP/dT` and `dP/drho` in the docs because those are the sensitivities future developers search for first.

$$
\frac{dP}{dT} = \frac{\rho k_B}{\mu m_u} + \frac{4 a T^3}{3}
$$

$$
\frac{dP}{d\rho} = \frac{k_B T}{\mu m_u}
$$

In code, these are the `pressure_temperature_derivative(...)` and `pressure_density_derivative(...)` helpers in `src/microphysics/eos.jl`.

## How it enters ASTRA

The EOS pressure is used directly in the hydrostatic row and in the transport helper. ASTRA does not store pressure as a separate solve-owned variable; it evaluates the EOS from the local cell state whenever a residual or derivative needs it.

The EOS also supplies `adiabatic_gradient = 0.4` and a specific heat value, but this page is only documenting the current bootstrap closure, not a general thermodynamic package.

## What is deferred

Real EOS tables, partial ionization, degeneracy, Coulomb corrections, and composition-rich thermodynamics are deferred. This page documents the placeholder closure ASTRA actually solves with today, not the closure we want for a production stellar model.
