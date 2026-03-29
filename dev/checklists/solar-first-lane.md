# Solar-First Lane Checklist

Last updated: **2026-03-29**

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

## Initialization lane

- [ ] Low-mass convective PMS seed builder implemented
- [ ] Relaxation pseudo-evolution stage implemented
- [ ] Mixed relaxation acceptance criteria implemented
- [ ] Accepted hydrostatic start-model handoff implemented

## Physics baseline

- [ ] EOS contract upgraded from toy closure toward classical baseline use
- [ ] Opacity contract upgraded from toy closure toward classical baseline use
- [ ] Source-decomposed energy equation implemented
- [ ] Gravothermal bookkeeping implemented in evolution ownership layer
- [ ] Real baseline MLT closure implemented

## Evolution lane

- [ ] PMS contraction sequence runs without manual intervention
- [ ] ZAMS criterion implemented with persistence check
- [ ] Main-sequence evolution reaches solar age target run

## Validation

- [ ] Tier 0 structural sanity checks implemented
- [ ] Tier 1 relaxation acceptance checks implemented
- [ ] Tier 2 PMS validation checks implemented
- [ ] Tier 3 ZAMS validation checks implemented
- [ ] Tier 4 compact solar target-vector validation implemented

## Explicitly deferred

- [ ] `alpha_MLT` calibration workflow
- [ ] isotope-vector composition state
- [ ] composition transport flux operators
- [ ] high-mass / protostellar seed family
- [ ] profile-level solar validation
- [ ] Entropy-DAE comparison lane
