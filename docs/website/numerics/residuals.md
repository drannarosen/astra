# Residuals

ASTRA's current residual vector is a bootstrap teaching device: it compares the current discrete state to an analytic reference profile with the same variable layout that the classical baseline will use later.

That choice gives us a real nonlinear system now, which is enough to validate:

- state packing,
- boundary row counts,
- solver iteration plumbing,
- and Jacobian assembly.

It also keeps the repo honest about the difference between architectural readiness and physics completeness.
