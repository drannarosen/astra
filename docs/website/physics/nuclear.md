# Nuclear Energy Generation

Nuclear heating tells the star where part of the luminosity source budget is created. In the full classical energy equation, it is only one contributor alongside gravothermal release and neutrino losses. ASTRA's bootstrap lane uses a toy heating law so the energy-generation row can participate in the real residual before the reaction network grows up.

## Current ASTRA implementation

ASTRA currently uses a toy pp-toy heating law:

`epsilon_nuc = 1.07e-7 * rho * X^2 * (T / 1.0e6)^4`

That gives the classical residual a smooth source term with the right qualitative temperature sensitivity, while remaining easy to differentiate and easy to reason about.

## Numerical realization in ASTRA

The luminosity row in [Residual Assembly](../methods/residual-assembly.md) subtracts $dm \, \varepsilon_\mathrm{nuc}$. The Jacobian audit in [Jacobian Construction](../methods/jacobian-construction.md) checks the local density and temperature derivatives that this closure contributes. The full classical energy equation should eventually combine this with `eps_grav` and `eps_nu`, corresponding to $\varepsilon_\mathrm{grav}$ and $\varepsilon_\nu$.

## What is deferred

Real reaction networks, screening physics, neutrino losses, gravothermal bookkeeping, and composition evolution are deferred. This page documents the current source term that ASTRA actually uses, not a full energy-source lane.

## Implementation checklist

- [x] The current toy nuclear source law is stated explicitly.
- [x] The page points to the exact luminosity-row owner.
- [x] The page states that `eps_grav` and `eps_nu` are not yet owned by the residual.
- [ ] The eventual gravothermal bookkeeping owner is linked once it exists.

## Validation checklist

- [ ] The source term and its derivatives are benchmarked against a reference artifact or regression envelope.
- [ ] The transition from toy heating to a richer source model is documented with an explicit parity or validation plan.
