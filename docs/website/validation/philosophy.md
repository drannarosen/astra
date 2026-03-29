# Validation Philosophy

ASTRA is not allowed to grow faster than it validates.

That principle matters especially at bootstrap because scientific software can look tidy long before it becomes trustworthy. The right early question is not "does the package exist?" It is "what does the current package actually prove?"

## Bootstrap evidence

The current scaffold is meant to validate:

- package loading,
- type and state construction,
- explicit ownership boundaries,
- docs coverage,
- example workflow integrity,
- and one toy nonlinear solve surface.

It does **not** yet validate the full classical structure equations.

## What passing current tests still does not prove

Passing the current suite does not mean:

- the hydrostatic equations are physically correct,
- the solar lane is validated,
- the evolution algorithm exists,
- or the microphysics closures are production-ready.

What it does mean is narrower and still useful: the ownership contract, package surfaces, example workflows, and bootstrap nonlinear-solve plumbing are internally consistent enough to build on.
