# Issues

This page tracks known limitations and unresolved questions that should stay visible while ASTRA grows.

## Active issues

### Classical residual convergence basin is still provisional

ASTRA's default classical initializer now includes center asymptotic targets, solver-side luminosity conditioning, a Phase 2 one-sided `T(\tau)` atmosphere boundary, and a higher-fidelity structured Jacobian. The public 12-cell example now takes accepted Newton steps again and lowers the weighted residual to a small finite value, but it still does not converge cleanly enough to call the classical lane robust. The remaining blocker is now a mix of closure maturity and accepted-step quality rather than "can ASTRA move at all?"

### Surface closure is now staged, not finished

The current outer boundary uses a Phase 2 one-sided `T(\tau)` atmosphere closure with shared helper-layer transport and pressure scaling rather than a guessed density. That is better than the old provisional closure, but it is still not proven across a broader convergence basin.

### Evolution remains intentionally stubbed

`step_evolution!` is contract-consistent with `StellarModel`, but there is still no accepted PMS or main-sequence evolution algorithm in code.

### Validation is still early-stage

The current test suite proves package integrity, ownership boundaries, example integrity, exact-row local derivative validation for the current toy helper kernels, the structured Jacobian audit surface, explicit solve-boundary diagnostics, and the staged atmosphere closure. It does not yet prove a trustworthy solar lane or a converged classical nonlinear solve.

## Questions to keep asking

- what should Phase 3 atmosphere comparison cover first after the Phase 2 helper-layer slice: explicit `T(\tau)` variants or tabulated atmosphere matching?
- what is the smallest accepted PMS seed-and-relaxation slice that gives a meaningful hydrostatic handoff and a better Newton starting model?
- when should ASTRA begin recording dated progress entries automatically from completed plans or merged slices?
