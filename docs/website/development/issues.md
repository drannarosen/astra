# Issues

This page tracks known limitations and unresolved questions that should stay visible while ASTRA grows.

## Active issues

### Classical residual convergence basin is still provisional

ASTRA's default classical initializer now lands at a materially smaller residual norm than the first residual slice by building a geometry-consistent shell profile and a source-matched toy luminosity profile. The solve now also uses a block-aware Jacobian path, but the bootstrap examples still stall at iteration 0 with `converged = false`. The remaining blocker is now the quality of the Newton update and the fidelity of the assembled Jacobian, not the old missing-contract or missing-diagnostics problems.

### Surface closure remains provisional

The current outer boundary uses a simple guessed surface density rather than a physically mature atmosphere treatment. That is acceptable for the first residual slice, but it remains a real limitation for later solar-lane work.

### Evolution remains intentionally stubbed

`step_evolution!` is contract-consistent with `StellarModel`, but there is still no accepted PMS or main-sequence evolution algorithm in code.

### Validation is still early-stage

The current test suite proves package integrity, ownership boundaries, example integrity, the first classical residual row semantics, one local derivative validation for the radiative-temperature-gradient helper, the block-aware Jacobian contract, and explicit solve-boundary diagnostics. It does not yet prove a trustworthy solar lane or a converged classical nonlinear solve.

## Questions to keep asking

- which classical closure should land first after the ownership refactor: EOS or opacity contract tightening?
- what is the smallest accepted PMS seed-and-relaxation slice that gives a meaningful hydrostatic handoff and a better Newton starting model?
- when should ASTRA begin recording dated progress entries automatically from completed plans or merged slices?
