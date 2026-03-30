# Analytical Nuclear Heating

ASTRA's current nuclear source is a staged analytical heating law with PP and CNO contributions. It exists so the energy-generation row has a more realistic source term and smooth derivatives during the classical bootstrap solve without widening the current ownership surface.

## Current formula

The current energy rate is the sum of analytical PP-chain and CNO-cycle terms, with optional triple-alpha compiled in but disabled by default. Weak screening can also be enabled as a flag-gated analytical enhancement for the PP and CNO branches. The returned quantity is still an energy rate in `erg g^-1 s^-1`. In ASTRA this is the exact `energy_rate_erg_g_s` payload from `src/microphysics/nuclear.jl`.

The teaching picture is:

- PP burning is the gentle hydrogen-burning branch that can matter at lower core temperatures,
- CNO is much more temperature-sensitive and therefore acts like a sharper thermostat once the core is hot enough,
- triple-alpha is the staged helium-burning branch and is kept default-off because this bootstrap lane is not yet abundance-evolving.

## Derivatives ASTRA uses

The current derivative payloads are

ASTRA tracks the literal payload names `dε/dT` and `dε/drho` because those are the source sensitivities the luminosity row consumes.

These are the `nuclear_temperature_derivative(...)` and `nuclear_density_derivative(...)` helpers in `src/microphysics/nuclear.jl`. ASTRA currently evaluates them with explicit centered local finite differences through the analytical closure, keeping the derivative owner inside the bootstrap microphysics layer without adding automatic differentiation.

## How it enters ASTRA

The luminosity residual subtracts `dm * epsilon_nuc` for each interior cell, so the source term enters the nonlinear solve as a volumetric heating rate rather than as a separate conserved variable. The Jacobian uses the local source derivatives above when the luminosity row is linearized.

The row-level realization is documented in [Residual Assembly](../../methods/residual-assembly.md), and the current linearization contract is described in [Jacobian Construction](../../methods/jacobian-construction.md).

## What is deferred

Real reaction networks, composition evolution, and detailed screening physics are deferred. Screening and triple-alpha remain flag-gated in the default path. Neutrino losses are not owned by this closure; they live in the broader analytical energy-source helper lane. This page documents the bootstrap heating source ASTRA actually uses today, not a full abundance-evolution or reaction-network package.
