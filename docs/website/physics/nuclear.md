# Nuclear Energy Generation

Nuclear heating tells the star where luminosity is created. ASTRA's bootstrap lane uses a toy heating law so the energy-generation row can participate in the real residual before the reaction network grows up.

## Current ASTRA implementation

ASTRA currently uses a toy pp-toy heating law:

`epsilon_nuc = 1.07e-7 * rho * X^2 * (T / 1.0e6)^4`

That gives the classical residual a smooth source term with the right qualitative temperature sensitivity, while remaining easy to differentiate and easy to reason about.

## Numerical realization in ASTRA

The luminosity row in [Residual Assembly](../methods/residual-assembly.md) subtracts `dm * epsilon_nuc`. The Jacobian audit in [Jacobian Construction](../methods/jacobian-construction.md) checks the local density and temperature derivatives that this closure contributes.

## What is deferred

Real reaction networks, screening physics, neutrino losses, and composition evolution are deferred. This page documents the current source term that ASTRA actually uses, not a full nuclear-physics lane.
