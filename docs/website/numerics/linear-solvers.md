# Linear Solvers

The bootstrap still uses Julia's dense backslash solve for the Newton update.

Canonical guide: [Linear Solves and Scaling](../methods/linear-solves-and-scaling.md).

This page stays as a compact numerics-side summary and is not the canonical numerical specification.

That is a placeholder decision, not a long-term endorsement of dense algebra for realistic stellar solves. The important architectural rule is that the nonlinear layer should delegate the update step to a linear-solver boundary instead of hard-coding one strategy everywhere.

Current status:

- the nonlinear solve now consumes the block-aware `structure_jacobian` path rather than the old global finite-difference Jacobian,
- the matrix is still dense at this stage,
- and `solve_linear_system` remains the explicit boundary where ASTRA can later introduce better factorizations or external linear-solver infrastructure.

## Summary checklist

- [x] This page explicitly points back to the canonical numerical specification in `Methods`.
- [x] This page explicitly says it is not the canonical numerical specification.
- [ ] Keep solver-scaling and regularization details owned by [Linear Solves and Scaling](../methods/linear-solves-and-scaling.md).
