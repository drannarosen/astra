# Stellar Structure

The classical 1D stellar-structure problem is a single coupled boundary-value problem in the enclosed-mass coordinate. It combines geometry, force balance, source balance, and energy transport into one nonlinear solve.

## What the coupled problem does

The four structure equations are:

- `dr/dm` for mass conservation and shell geometry
- `dP/dm` for hydrostatic support
- `dL/dm` for energy generation
- `dT/dm` for energy transport

ASTRA now arranges those equations on a staggered mesh with face-centered radius and luminosity, and cell-centered density and temperature. That is the classical baseline lane, not a finished stellar-evolution package.

## Current ASTRA implementation

The current residual has one geometric row, one hydrostatic row, one luminosity row, and one transport row per interior zone, plus center and surface boundary rows. The interior rows are built from the current toy EOS, opacity, and nuclear closures, so the solver can exercise the full residual chain before the microphysics grows up.

That means the code is already solving the right *kind* of nonlinear system, but still with intentionally simple closures:

- shell-volume geometry in the mass row
- ideal-gas-plus-radiation pressure in the hydrostatic row
- toy pp-like heating in the luminosity row
- radiative-gradient transport in the temperature row

## Numerical realization in ASTRA

The residual assembly lives in [Residual Assembly](../methods/residual-assembly.md). The solver boundary and variable ownership live in [From Equations to Residual](../methods/from-equations-to-residual.md) and [Staggered Mesh and State Layout](../methods/staggered-mesh-and-state-layout.md). Jacobian quality is tracked in [Jacobian Construction](../methods/jacobian-construction.md).

## What is deferred

The current page is the classical baseline only. A validated solar model, realistic EOS/opacity tables, MLT, composition transport, PMS evolution, and Entropy-DAE all remain deferred until the classical residual is numerically trustworthy.
