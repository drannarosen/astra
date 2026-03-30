# pp-Toy Heating

ASTRA's current nuclear source is a toy pp-inspired heating law. It exists so the energy-generation row has a smooth source term and smooth derivatives during the classical bootstrap solve.

## Current formula

The current energy rate is

$$
\varepsilon_\mathrm{nuc}(\rho, T, X) = 1.07 \times 10^{-7} \, \rho \, X^2 \left(\frac{T}{10^6}\right)^4
$$

where the returned quantity is an energy rate in `erg g^-1 s^-1`. In ASTRA this is the exact `energy_rate_erg_g_s` payload from `src/microphysics/nuclear.jl`.

## Derivatives ASTRA uses

The current derivative payloads are

ASTRA tracks the literal payload names `dε/dT` and `dε/drho` because those are the source sensitivities the luminosity row consumes.

$$
\frac{d\varepsilon}{dT} = 4 \, \frac{\varepsilon}{T}
$$

$$
\frac{d\varepsilon}{d\rho} = 1.07 \times 10^{-7} \, X^2 \left(\frac{T}{10^6}\right)^4
$$

These are the `nuclear_temperature_derivative(...)` and `nuclear_density_derivative(...)` helpers in `src/microphysics/nuclear.jl`.

## How it enters ASTRA

The luminosity residual subtracts `dm * epsilon_nuc` for each interior cell, so the source term enters the nonlinear solve as a volumetric heating rate rather than as a separate conserved variable. The Jacobian uses the local source derivatives above when the luminosity row is linearized.

The row-level realization is documented in [Residual Assembly](../../methods/residual-assembly.md), and the current linearization contract is described in [Jacobian Construction](../../methods/jacobian-construction.md).

## What is deferred

Real reaction networks, neutrino losses, composition evolution, and detailed screening physics are deferred. This page documents the bootstrap source ASTRA actually uses today, not the pp-chain in full physical detail.
