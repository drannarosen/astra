# Residual Ownership

In ASTRA, the **residual** is the list of equations the solver is trying to drive to zero. Residual ownership therefore means ownership of equation meaning. The residual should say what physical statement each row represents, while the closure layers supply the local physics coefficients and source terms those rows need.

That sounds abstract until a codebase loses it. Once the residual starts hiding EOS logic, opacity details, source-term bookkeeping, and timestep logic all in one place, the equations stop being readable as equations.

## What the residual owns

For the classical baseline, ASTRA's interior residual conceptually carries four structure equations per cell:

1. geometric or mass-continuity relation,
2. hydrostatic-equilibrium relation,
3. luminosity or energy relation,
4. temperature-gradient or transport relation.

The residual owns the ordering, signs, coupling pattern, and physical meaning of those rows. In plain language, it owns the sentence "what equation are we solving here?"

## What the residual does not own

The residual should not bury the internal details of:

- EOS interpolation,
- opacity interpolation,
- nuclear-rate implementation,
- convection-model internals,
- or timestep-aware gravothermal bookkeeping.

Instead, it asks the appropriate layer for pressure, thermodynamic derivatives, opacity, source terms such as `eps_nuc`, and evolution-aware terms such as `eps_grav`. For the full classical energy accounting, the architecture should also leave an explicit slot for neutrino losses such as `eps_nu`, even when that term is still deferred numerically.

## Residual ordering

The approved ordering for the classical lane is:

1. center boundary conditions,
2. interior structure equations cell by cell,
3. surface boundary conditions.

That order is worth teaching explicitly. It helps the code, the diagnostics, and the Jacobian all line up with the physics being modeled.

## The energy-equation contract

ASTRA's first serious energy equation should be **source-decomposed**. In plain language, that means the energy row should keep different physical sources and losses visibly separate instead of folding them into one anonymous term.

At minimum, the architecture should reserve explicit ownership slots for:

- `eps_nuc`,
- `eps_grav`,
- and loss terms such as `eps_nu`.

Some of those terms may remain provisional early on. The ownership should not. Pre-main-sequence evolution and later comparison work depend on getting the bookkeeping boundary right from the start.

## Why this matters later

If every new closure becomes a special case hidden inside residual assembly, ASTRA will become opaque very quickly. If the residual keeps ownership of equation semantics while microphysics and evolution provide closures, then better EOS models, richer source terms, and later formulation comparisons remain local changes instead of whole-code rewrites.

## Ownership checklist

- [x] The page defines residual ownership as ownership of equation meaning, not closure internals.
- [x] The classical four-row interior structure picture is stated explicitly.
- [x] The page distinguishes residual semantics from microphysics and evolution responsibilities.
- [x] The energy-equation contract names `eps_nuc`, `eps_grav`, and `eps_nu` as separate ownership slots.
- [x] The residual ordering is stated in the same order the physics is read.
