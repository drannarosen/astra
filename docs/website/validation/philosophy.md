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

That distinction is central to the whole handbook. ASTRA is trying to become a trustworthy stellar-structure engine, and trustworthy means more than "tests passed." A validation claim should tell a contributor exactly which layer has been checked:

- code-shape sanity,
- equation ownership,
- derivative fidelity,
- numerical convergence behavior,
- or physical agreement with an external reference.

Blurring those layers is how research software starts to sound more mature than it really is.

## Validation checklist

- [x] The page states what the current tests do validate.
- [x] The page states what the current tests do not validate.
- [ ] Every major handbook page should link to the relevant validation surface for its claims.
- [ ] ASTRA still needs benchmark artifacts before the website can describe the classical lane as physically validated.
