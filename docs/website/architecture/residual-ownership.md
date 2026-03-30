# Residual Ownership

In ASTRA, the **residual** is the list of equations the solver is trying to drive to zero. Residual ownership therefore means ownership of equation meaning. The residual should say what physical statement each row represents, while the closure layers supply the local physics coefficients and source terms those rows need.

Here, a **closure** is a local physics rule the residual calls on, such as an EOS, opacity law, or source-term model.

This distinction is easy to blur in practice. Once residual assembly starts absorbing EOS details, opacity logic, source bookkeeping, and timestep control, the equations stop being inspectable as equations.

The clean ASTRA split is this: state owns persisted quantities, closures own local constitutive physics, and the residual owns discrete equation meaning. The residual consumes model state and closure outputs, but it does not redefine either one. State says what the model currently is; closures say how local physics is evaluated; the residual says what equations must vanish.

## What the residual owns

For the classical baseline, ASTRA's interior residual conceptually carries four interior row families on the chosen staggered mesh:

1. **Geometry / mass continuity**, which says shell volume and density must agree with the mass assigned to the cell.
2. **Hydrostatic equilibrium**, which says pressure support must balance gravity.
3. **Energy conservation**, which says luminosity changes must match local sources and losses.
4. **Transport / temperature gradient**, which says the temperature drop outward must be consistent with the transport model.

The residual owns the ordering, signs, coupling pattern, and physical meaning of those rows. In plain language, it owns what equation each row is trying to enforce.

Residual ownership therefore includes the mapping from physical statements to discrete rows on the chosen staggered mesh.

## What the residual does not own

The residual should not bury the internal details of:

- EOS interpolation,
- opacity interpolation,
- nuclear-rate implementation,
- convection-model internals,
- or timestep-aware gravothermal bookkeeping.

Instead, it asks the appropriate layer for pressure, thermodynamic derivatives, opacity, source terms such as `eps_nuc`, and evolution-aware terms such as `eps_grav`. For the full classical energy accounting, the architecture should also leave an explicit slot for neutrino losses such as `eps_nu`, even when that term is still deferred numerically.

For example, if the hydrostatic row needs pressure, the residual owns the balance equation being enforced while the EOS owns how pressure is computed from the current state.

The residual must not become a miscellaneous container for EOS logic, transport heuristics, timestep control, or hidden diagnostics.

## Residual ordering

The approved ordering for the classical lane is:

1. center boundary conditions,
2. interior structure equations cell by cell,
3. surface boundary conditions.

That order is worth teaching explicitly because it helps the code, the diagnostics, and the Jacobian all line up with the physics being modeled.

## Residual guarantees

The current ASTRA operator contract should preserve a few simple guarantees:

- each row family has a stable physical meaning,
- row ordering is documented,
- sign conventions are fixed by the discrete contract rather than left implicit,
- closure dependencies are explicit,
- and boundary rows are not mixed into interior semantics.

## The energy-equation contract

ASTRA's first serious energy equation should be **source-decomposed**. In plain language, that means the energy row should keep different physical sources and losses visibly separate instead of folding them into one anonymous term.

At minimum, the architecture should reserve explicit ownership slots for:

- `eps_nuc`,
- `eps_grav`,
- and loss terms such as `eps_nu`.

Some of those terms may remain provisional early on. The ownership should not. Pre-main-sequence evolution and later comparison work depend on getting the bookkeeping boundary right from the start.

The key architectural point is simple: the residual owns this decomposition even if some source terms are still numerically stubbed or approximated.

## Why this matters later

If every new closure becomes a special case hidden inside residual assembly, ASTRA will become opaque very quickly. If the residual keeps ownership of equation semantics while microphysics and evolution provide closures, then better EOS models, richer source terms, and later formulation comparisons can remain local changes instead of forcing whole-code rewrites.

This separation also matters for later differentiability work. Keeping closure internals out of residual ownership is what makes operator-level sensitivity analysis and later implicit differentiation tractable.

## Internal QA checklist

### Contract clarity

- [x] The page defines the state / residual / closure split explicitly.
- [x] The four interior row families are named and given a short physical interpretation.
- [x] The page distinguishes residual semantics from microphysics and evolution responsibilities with a concrete pressure example.

### Discrete operator guarantees

- [x] The page states that residual ownership includes the mapping from physics to discrete rows on the chosen mesh.
- [x] The page records the core residual guarantees: stable row meaning, documented ordering, explicit closure dependencies, and separate boundary semantics.
- [x] The residual ordering is stated in the same order the physics is read.

### Energy and future growth

- [x] The energy-equation contract names `eps_nuc`, `eps_grav`, and `eps_nu` as separate ownership slots.
- [x] The page states that the residual owns the decomposition even when some terms remain provisional.
- [x] The page connects clean residual ownership to later implicit differentiation and operator-level sensitivity work.
