# Residual Ownership

ASTRA's residual should own the meaning of the equations, not the internals of the closure models.

That sounds abstract, but it is one of the most important design rules in the codebase.

## What the residual owns

For the classical baseline, ASTRA's interior residual should conceptually carry four structure equations per cell:

1. geometric or mass-continuity relation,
2. hydrostatic-equilibrium relation,
3. luminosity or energy relation,
4. temperature-gradient or transport relation.

The residual is responsible for assembling those equations in a physically legible order.

## What the residual does not own

The residual should not bury the implementation details of:

- EOS interpolation,
- opacity interpolation,
- nuclear-rate implementation,
- convection-model internals,
- or timestep-aware gravothermal bookkeeping.

Instead, it should ask the appropriate layer for:

- pressure and thermodynamic derivatives,
- opacity and opacity derivatives,
- source terms such as `eps_nuc`,
- and evolution-aware terms such as `eps_grav`.

## Residual ordering

The approved ordering for the classical lane is:

1. center boundary conditions,
2. interior structure equations cell by cell,
3. surface boundary conditions.

This gives the residual a physically readable structure that also makes diagnostics and Jacobian interpretation easier.

## The energy equation contract

ASTRA's first serious energy equation should be designed as a **source-decomposed** equation with explicit slots for:

- `eps_nuc`,
- `eps_grav`,
- and loss terms.

Some of those terms can be stubbed in early milestones, but the ownership must be correct from the beginning because PMS evolution requires gravothermal energy release.

## Why this matters for later physics

If ASTRA treats every new closure or source term as a special case inside the residual, the code will become opaque very quickly.

If ASTRA instead keeps the residual as the owner of the equation semantics and lets microphysics and evolution provide the needed closures, then:

- upgrading EOS and opacity models stays local,
- adding composition evolution stays local,
- and later method comparison remains possible without rewriting the whole package.
