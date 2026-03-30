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

## Implementation checklist

- [x] The current EOS closure is stated explicitly.
- [x] The page says pressure is derived from state, not solve-owned directly.
- [ ] The exact thermodynamic derivative basis needed by every current Jacobian row is summarized and linked to tests.

## Validation checklist

- [ ] Pressure and derivative formulas are benchmarked against an independent reference for representative states.
- [ ] The adiabatic-gradient placeholder is replaced or justified quantitatively before this page can claim production-grade thermodynamics.
