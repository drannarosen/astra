# Equation of State

The equation of state closes the stellar-structure problem by turning density, temperature, and composition into pressure and thermodynamic response. In ASTRA's bootstrap lane, that closure is now a staged analytical gas-plus-radiation model with explicit local derivatives and explicit deferred physics.

## Current ASTRA implementation

ASTRA currently uses an analytical gas plus radiation EOS:

`P = rho k_B T / (mu m_u) + a T^4 / 3`

The same closure also supplies a beta-dependent adiabatic gradient, a beta-based specific heat at constant pressure, pressure derivatives, and the staged `chi_rho` / `chi_T` terms that the gravothermal helper lane now uses. The public closure payload remains intentionally narrow: pressure, gas-pressure fraction, adiabatic gradient, specific heat, and the local thermodynamic response terms ASTRA already consumes. Degeneracy and Coulomb corrections now exist as flag-gated analytical enrichments, but the documented default path is still fully explicit gas plus radiation.

## Numerical realization in ASTRA

The EOS is evaluated in the residual through [Residual Assembly](../methods/residual-assembly.md) and differentiated in [Jacobian Construction](../methods/jacobian-construction.md). The current implementation keeps pressure derived from the local cell state; it is not stored as an independent solver variable.

## What is deferred

Real EOS tables, partial ionization, entropy-authoritative inversion, and composition-rich thermodynamics are deferred. Degeneracy and Coulomb terms are not active in the default bootstrap lane yet, even though the staged closure now carries validated flag-gated analytical forms for future promotion. This page is the place to explain the closure ASTRA actually has now, not the closure we will want later.

## Implementation checklist

- [x] The current analytical gas-plus-radiation EOS is stated explicitly.
- [x] The page says pressure is derived from state, not solve-owned directly.
- [x] The current beta-based thermodynamic payload is summarized at the level ASTRA actually consumes.
- [x] The page distinguishes default gas-plus-radiation behavior from flag-gated degeneracy and Coulomb enrichments.

## Validation checklist

- [ ] Pressure and derivative formulas are benchmarked against an independent reference for representative states.
- [ ] Degeneracy and Coulomb terms remain disabled until derivative validation justifies enabling them in the bootstrap lane.
