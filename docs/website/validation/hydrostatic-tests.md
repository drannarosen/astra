# Hydrostatic Tests

The real hydrostatic test suite belongs to a later milestone. For now, ASTRA's hydrostatic-facing tests are scaffold tests:

- grid monotonicity,
- state dimension consistency,
- boundary row counts,
- residual-vector shape,
- convergence-basin improvement and honest non-convergence reporting on the current classical slice,
- local derivative validation for the radiative-temperature-gradient helper,
- and block-aware Jacobian agreement against the dense finite-difference reference.

These are meaningful because they protect the interfaces that the current classical residual already relies on.

## What the next hydrostatic tests should prove

Now that ASTRA has replaced the old reference-profile residual, the hydrostatic-facing tests should continue shifting toward the ownership contract rather than raw file coverage.

That means testing:

- the staggered structure layout,
- the canonical residual ordering,
- EOS closure consistency in a `rho, T, composition` basis,
- boundary-condition closure at center and surface,
- and source-term accounting for the energy equation.
