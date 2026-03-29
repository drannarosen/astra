# Issues

This page tracks known limitations and unresolved questions that should stay visible while ASTRA grows.

## Active issues

### Bootstrap residual is still pedagogical

The current residual system is an analytic reference-profile comparison, not the full classical stellar-structure equations. That means passing the current solver tests proves interface discipline and ownership, not physical hydrostatic fidelity.

### Evolution remains intentionally stubbed

`step_evolution!` is contract-consistent with `StellarModel`, but there is still no accepted PMS or main-sequence evolution algorithm in code.

### Validation is still early-stage

The current test suite proves package integrity, ownership boundaries, example integrity, and the toy nonlinear-solve surface. It does not yet prove a trustworthy solar lane.

## Questions to keep asking

- which classical closure should land first after the ownership refactor: EOS or opacity contract tightening?
- what is the smallest accepted PMS seed-and-relaxation slice that gives a meaningful hydrostatic handoff?
- when should ASTRA begin recording dated progress entries automatically from completed plans or merged slices?
