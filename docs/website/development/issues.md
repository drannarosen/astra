# Issues

This page tracks known limitations and unresolved questions that should stay visible while ASTRA grows.

## Active issues

### Classical residual convergence basin is still provisional

ASTRA now uses the first classical stellar-structure residual, but the current `initialize_state` does not yet place Newton in a robust convergence basin. The solver now reports that honestly with non-converged diagnostics instead of pretending the structure solve is complete.

### Surface closure remains provisional

The current outer boundary uses a simple guessed surface density rather than a physically mature atmosphere treatment. That is acceptable for the first residual slice, but it remains a real limitation for later solar-lane work.

### Evolution remains intentionally stubbed

`step_evolution!` is contract-consistent with `StellarModel`, but there is still no accepted PMS or main-sequence evolution algorithm in code.

### Validation is still early-stage

The current test suite proves package integrity, ownership boundaries, example integrity, the first classical residual row semantics, and solver/diagnostic honesty on that residual. It does not yet prove a trustworthy solar lane.

## Questions to keep asking

- which classical closure should land first after the ownership refactor: EOS or opacity contract tightening?
- what is the smallest accepted PMS seed-and-relaxation slice that gives a meaningful hydrostatic handoff and a better Newton starting model?
- when should ASTRA begin recording dated progress entries automatically from completed plans or merged slices?
