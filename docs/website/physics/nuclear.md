# Nuclear Energy Generation

Nuclear heating tells the star where part of the luminosity source budget is created. In the full classical energy equation, it is only one contributor alongside gravothermal release and neutrino losses. ASTRA's bootstrap lane now uses a staged analytical PP-plus-CNO heating law so the energy-generation row can participate in the real residual with a more realistic temperature sensitivity before the reaction network grows up.

## Current ASTRA implementation

ASTRA currently uses an analytical nuclear-heating closure with:

- PP-chain heating,
- CNO-cycle heating,
- optional triple-alpha compiled in but disabled by default,
- screening available as a flag-gated weak-Salpeter enhancement for PP and CNO.

The public payload is still intentionally narrow: ASTRA returns only `energy_rate_erg_g_s` and a `:analytical_nuclear` source tag. Composition-evolution payloads such as `dX_dt` and `dY_dt` are not part of the current public closure contract.

## Numerical realization in ASTRA

The luminosity row in [Residual Assembly](../methods/residual-assembly.md) now consumes a source-decomposed helper payload, so the analytical nuclear closure feeds the `eps_nuc` contribution inside a row that also owns `eps_grav` and `eps_nu`. The Jacobian audit in [Jacobian Construction](../methods/jacobian-construction.md) checks the local density and temperature derivatives that this closure contributes to that combined energy-source lane.

## What is deferred

Real reaction networks, intermediate/strong screening physics, and composition evolution are deferred. Triple-alpha and screening remain flag-gated rather than default-on. This page documents the current source term that ASTRA actually uses, not a full energy-source lane.

## Implementation checklist

- [x] The current analytical nuclear source law is stated explicitly.
- [x] The page points to the exact luminosity-row owner.
- [x] The page states that `eps_grav` and `eps_nu` are now owned by the source-decomposed residual helper lane.
- [x] The page states that composition evolution is still outside the public closure payload.
- [ ] The eventual gravothermal bookkeeping owner is linked once it exists.

## Validation checklist

- [ ] The source term and its derivatives are benchmarked against a reference artifact or regression envelope.
- [ ] The transition from analytical heating to a richer source model is documented with an explicit parity or validation plan.
