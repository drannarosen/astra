# Jacobians

ASTRA now carries two Jacobian paths with different jobs:

Canonical guide: [Jacobian Construction](../methods/jacobian-construction.md).

This page stays as a compact numerics-side summary.

- `finite_difference_jacobian(problem, model)` remains the global dense reference used for validation,
- `structure_jacobian(problem, model)` is the current solver-facing block-aware path.

The block-aware path still returns a dense matrix today, but it is assembled in physical row blocks:

1. center boundary rows,
2. interior cell blocks,
3. surface boundary rows.

Within each row block, ASTRA now splits the work by derivative fidelity:

- center radius and center luminosity rows use explicit local partials,
- interior geometry and interior luminosity rows use explicit local partials,
- hydrostatic and transport rows remain fallback rows,
- but those fallback rows now use block-local central differences rather than the old forward-difference perturbations.

That is already a meaningful architectural improvement over globally perturbing every unknown for every row because it makes the residual ordering and dependency structure explicit in code and moves the cleanest rows off the finite-difference path entirely.

Current caveat:

- hydrostatic and transport rows are still not analytic,
- the surface block is still finite-difference fallback,
- so the new path is not yet a fully analytic Jacobian,
- and the old global finite-difference matrix remains the comparison reference in tests.

That is acceptable for the current milestone. The important gain is that ASTRA now has a named structured Jacobian boundary with a verified split between analytic rows and higher-fidelity local fallback rows, and the public 24-cell example now takes 8 accepted Newton steps instead of stalling after one weak accepted update.
