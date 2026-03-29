# Hydrostatic Tests

The real hydrostatic test suite belongs to a later milestone. For now, ASTRA's hydrostatic-facing tests are scaffold tests:

- grid monotonicity,
- state dimension consistency,
- boundary row counts,
- residual-vector shape,
- and solver convergence on the analytic reference profile.

These are meaningful because they protect the interfaces that the classical residual will later rely on.

## What the next hydrostatic tests should prove

Once ASTRA starts replacing the toy residual, the hydrostatic-facing tests should be organized around the ownership contract rather than around raw file coverage.

That means testing:

- the staggered structure layout,
- the canonical residual ordering,
- EOS closure consistency in a `rho, T, composition` basis,
- boundary-condition closure at center and surface,
- and source-term accounting for the energy equation.
