# Nuclear Energy Generation

Nuclear heating tells the star where part of the luminosity source budget is created. In the full classical energy equation, it is only one contributor alongside gravothermal release and neutrino losses. ASTRA's bootstrap lane now uses a staged analytical PP-plus-CNO heating law so the energy-generation row can participate in the real residual with a more realistic temperature sensitivity before the reaction network grows up.

## Current ASTRA implementation

ASTRA currently uses an analytical nuclear-heating closure with:

- PP-chain heating,
- CNO-cycle heating,
- optional triple-alpha compiled in but disabled by default,
- screening carried as a disabled flag in this slice.

The public payload is still intentionally narrow: ASTRA returns only `energy_rate_erg_g_s` and a `:analytical_nuclear` source tag. Composition-evolution payloads such as `dX_dt` and `dY_dt` are not part of the current public closure contract.

## Numerical realization in ASTRA

The luminosity row in [Residual Assembly](../methods/residual-assembly.md) subtracts $dm \, \varepsilon_\mathrm{nuc}$. The Jacobian audit in [Jacobian Construction](../methods/jacobian-construction.md) checks the local density and temperature derivatives that this closure contributes. The full classical energy equation should eventually combine this with `eps_grav` and `eps_nu`, corresponding to $\varepsilon_\mathrm{grav}$ and $\varepsilon_\nu$.

## What is deferred

Real reaction networks, screening physics, neutrino losses, gravothermal bookkeeping, and composition evolution are deferred. Triple-alpha and screening remain disabled in the default path. This page documents the current source term that ASTRA actually uses, not a full energy-source lane.

## Implementation checklist

- [x] The current analytical nuclear source law is stated explicitly.
- [x] The page points to the exact luminosity-row owner.
- [x] The page states that `eps_grav` and `eps_nu` are not yet owned by the residual.
- [x] The page states that composition evolution is still outside the public closure payload.
- [ ] The eventual gravothermal bookkeeping owner is linked once it exists.

## Validation checklist

- [ ] The source term and its derivatives are benchmarked against a reference artifact or regression envelope.
- [ ] The transition from analytical heating to a richer source model is documented with an explicit parity or validation plan.
