# Hydrostatic Tests

The real hydrostatic test suite belongs to a later milestone. For now, ASTRA's hydrostatic-facing tests are scaffold tests:

- grid monotonicity,
- state dimension consistency,
- boundary row counts,
- residual-vector shape,
- and solver convergence on the analytic reference profile.

These are meaningful because they protect the interfaces that the classical residual will later rely on.
