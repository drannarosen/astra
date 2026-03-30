# Solar-First Lane Checklist

Last updated: **2026-03-30**

This checklist tracks ASTRA's first serious science lane:

- low-mass PMS seed,
- relaxation,
- PMS contraction,
- ZAMS detection,
- main-sequence evolution to solar age.

## Contracts and design

- [x] State and residual ownership contract written
- [x] Cell-centered composition plus future isotope/transport path documented
- [x] ZAMS defined primarily by energy partition
- [x] Solar target vector kept compact for the first milestone
- [x] Baseline convection policy set to real MLT with fixed `alpha_MLT`
- [x] Scope-discipline rule documented
- [x] Examples and handbook updated to explicit `StellarModel` ownership language

## Code architecture

- [x] `StructureState` introduced in code
- [x] `CompositionState` introduced in code
- [x] `EvolutionState` introduced in code
- [x] Top-level model container introduced in code
- [x] Pack/unpack limited to the structure solve-owned block
- [x] Residual ordering encoded explicitly in tests
- [x] Weighted Newton residual/correction metrics and correction limiting implemented without widening the public solve-owned state
- [x] Phase 2 one-sided `T(\tau)` atmosphere boundary implemented for the classical outer solve
- [x] Phase 2 atmosphere design choice recorded: preserve current outer `R/L` ownership while upgrading to a one-sided `T(\tau)` thermodynamic reconstruction
- [x] Outer transport row and surface pressure scale routed through the shared Phase 2 helper layer

## Initialization lane

- [ ] Low-mass convective PMS seed builder implemented
- [ ] Relaxation pseudo-evolution stage implemented
- [ ] Mixed relaxation acceptance criteria implemented
- [ ] Accepted hydrostatic start-model handoff implemented

## Physics baseline

- [x] EOS contract upgraded from toy closure toward classical baseline use
- [x] Opacity contract upgraded from toy closure toward classical baseline use
- [x] Source-decomposed energy equation implemented
- [x] `eps_grav` gravothermal bookkeeping implemented in evolution ownership layer
- [x] `eps_grav` consumes EOS-owned `chi_rho` / `chi_T` response terms in staged enriched regimes
- [x] Staged `eps_nu` loss term wired into the luminosity source decomposition
- [x] Surface closure upgraded from guessed thermodynamic values to one-sided Phase 2 `T(\tau)` atmosphere matching
- [x] Weak-screening analytical nuclear option implemented and tested
- [x] Flag-gated degeneracy and Coulomb EOS enrichments implemented and tested
- [ ] Real baseline MLT closure implemented

## Evolution lane

- [ ] PMS contraction sequence runs without manual intervention
- [ ] ZAMS criterion implemented with persistence check
- [ ] Main-sequence evolution reaches solar age target run

## Validation

- [x] Tier 0 structural sanity checks implemented
- [ ] Tier 1 relaxation acceptance checks implemented
- [ ] Tier 2 PMS validation checks implemented
- [ ] Tier 3 ZAMS validation checks implemented
- [ ] Tier 4 compact solar target-vector validation implemented
- [x] Atmosphere Phase 2 `T(\tau)` upgrade implemented
- [ ] Atmosphere Phase 2 convergence-basin evidence recorded after implementation

## Explicitly deferred

- [ ] `alpha_MLT` calibration workflow
- [ ] isotope-vector composition state
- [ ] composition transport flux operators
- [ ] default-on promotion for screening, triple-alpha, degeneracy, and Coulomb terms
- [ ] high-mass / protostellar seed family
- [ ] profile-level solar validation
- [ ] Entropy-DAE comparison lane
