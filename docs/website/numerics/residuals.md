# Residuals

ASTRA's current residual vector is a bootstrap teaching device: it compares the current discrete state to an analytic reference profile with the same variable layout that the classical baseline will use later.

That choice gives us a real nonlinear system now, which is enough to validate:

- state packing,
- boundary row counts,
- solver iteration plumbing,
- and Jacobian assembly.

It also keeps the repo honest about the difference between architectural readiness and physics completeness.

## The approved classical target

The future classical residual is now constrained by an explicit contract:

- center boundary rows first,
- interior structure equations next,
- surface boundary rows last.

Within the interior, ASTRA should conceptually carry:

1. geometric or mass-continuity closure,
2. hydrostatic equilibrium,
3. luminosity or energy conservation,
4. temperature-gradient or transport closure.

The energy equation should be source-decomposed from the start, with explicit slots for nuclear, gravothermal, and loss terms even if some are initially stubbed.
