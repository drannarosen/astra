# Equation of State

The equation of state closes the stellar-structure problem by turning density, temperature, and composition into pressure and thermodynamic response. In ASTRA's bootstrap lane, that closure is intentionally simple and fully explicit.

## Current ASTRA implementation

ASTRA currently uses an ideal gas plus radiation EOS:

`P = rho k_B T / (mu m_u) + a T^4 / 3`

The same closure also supplies a fixed adiabatic gradient and the pressure derivatives that the Jacobian needs. That is enough for the classical residual to ask the EOS for the quantities it owns without pretending the thermodynamics are production grade.

## Numerical realization in ASTRA

The EOS is evaluated in the residual through [Residual Assembly](../methods/residual-assembly.md) and differentiated in [Jacobian Construction](../methods/jacobian-construction.md). The current implementation keeps pressure derived from the local cell state; it is not stored as an independent solver variable.

## What is deferred

Real EOS tables, partial ionization, degeneracy, Coulomb corrections, and composition-rich thermodynamics are deferred. This page is the place to explain the closure ASTRA actually has now, not the closure we will want later.
