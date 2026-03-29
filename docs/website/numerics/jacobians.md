# Jacobians

ASTRA now carries two Jacobian paths with different jobs:

- `finite_difference_jacobian(problem, model)` remains the global dense reference used for validation,
- `structure_jacobian(problem, model)` is the current solver-facing block-aware path.

The block-aware path still returns a dense matrix today, but it is assembled in physical row blocks:

1. center boundary rows,
2. interior cell blocks,
3. surface boundary rows.

Within each row block, ASTRA perturbs only the local state entries that the corresponding residual rows actually depend on. That is already a meaningful architectural improvement over globally perturbing every unknown for every row because it makes the residual ordering and dependency structure explicit in code.

Current caveat:

- many entries still use local finite-difference fallback inside each block,
- so the new path is not yet a fully analytic Jacobian,
- and the old global finite-difference matrix remains the comparison reference in tests.

That is acceptable for the current milestone. The important gain is that ASTRA now has a named structured Jacobian boundary that later slices can replace block by block with explicit partials.
