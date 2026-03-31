# Physics

ASTRA's physics pages explain the continuous stellar-structure model before the discretization details begin. The goal is to keep the science legible for students and the implementation honest for developers: what equations are solved, what closures are supplied, and what is still stubbed.

This section is the canonical continuous-equation surface for ASTRA. If a page in `Methods` says how a residual row is assembled, the matching page in `Physics` should answer a different question: what physical statement that row is trying to approximate, what assumptions make the equation valid, and what closure data the row still needs before it can be evaluated.

## Structure equations

The classical baseline is the coupled four-equation problem in enclosed mass:

- mass conservation, shorthand `dr/dm`: $\frac{dr}{dm}$
- hydrostatic equilibrium, shorthand `dP/dm`: $\frac{dP}{dm}$
- energy generation, shorthand `dL/dm`: $\frac{dL}{dm}$
- energy transport, shorthand `dT/dm`: $\frac{dT}{dm}$

Those equations appear in [Stellar Structure](stellar-structure.md), and ASTRA currently solves their discrete residual form on a staggered face/cell mesh.

The important teaching point is that these equations are not four unrelated formulas. Together they answer four coupled questions about the same star:

- how much volume a shell occupies,
- how pressure must change to support the weight above it,
- how luminosity is produced or lost as we move outward,
- and how temperature adjusts so that the energy can actually be carried.

That is why ASTRA treats stellar structure as a boundary-value problem rather than as a shell-by-shell bookkeeping exercise. Changing one of these equations changes the meaning of the others.

## Constitutive physics

Here, constitutive physics means the local closure laws that tell the structure equations how matter and radiation behave.

The structure equations are not closed until we choose an equation of state, an opacity law, a nuclear heating law, and a transport closure. ASTRA's bootstrap lane currently uses staged analytical physics:

- [Equation of State](eos.md): staged analytical gas plus radiation, with flag-gated degeneracy and Coulomb enrichments
- [Opacity](opacity.md): analytical Kramers + H-minus + electron scattering
- [Nuclear Energy Generation](nuclear.md): analytical PP + CNO heating, with flag-gated weak screening and triple-alpha
- [Convection](convection.md): radiative-only residual plus instability criteria today, with Bohm-Vitense local MLT as the canonical target

These pages explain the physics and state plainly what ASTRA actually computes today.

For new contributors, this is one of the most important distinctions in the handbook:

- the structure equations are the universal continuous statements,
- the closure pages explain how ASTRA turns symbols such as $P(\rho, T)$ or $\kappa(\rho, T)$ into actual numbers and derivatives,
- and the methods pages explain how those continuous statements are turned into a nonlinear algebra problem.

## Boundary conditions

Boundary conditions are the extra center and surface conditions that close the global stellar-structure problem.

The center and surface close the global solve. The center uses asymptotic series targets for the innermost face, and the surface now uses a staged Eddington-grey atmosphere closure. See [Boundary Conditions](boundary-conditions.md) for the current closure, [Atmosphere and Photosphere](atmosphere-and-photosphere.md) for the photospheric meaning and planned phases, and [Methods](../methods/overview.md) for how those conditions enter the residual.

This matters numerically because the center and surface are exactly where the naive differential forms become least trustworthy. The center is formally singular in several common rearrangements, and the outer boundary is where a stellar interior model must decide how it is being matched to an atmosphere or outer-layer prescription.

## Current ASTRA implementation

ASTRA currently solves a classical residual, meaning the vector of equation mismatches the solver tries to drive to zero.

ASTRA currently solves a classical residual with `log(radius)`, `log(temperature)`, and `log(density)` as the thermodynamic/geometry unknowns, while keeping luminosity in raw cgs $\mathrm{erg\,s^{-1}}$. The result is a bootstrap classical solve, not a production stellar model, but the ownership of each quantity is now explicit enough that the equations can be hardened step by step.

That solve-variable choice is deliberate. Stellar structure spans many orders of magnitude in radius, temperature, and density, so ASTRA expresses those unknowns in logarithmic form to keep positivity explicit and to make Newton updates better conditioned. The continuous equations are still written in physical variables; the numerics layer applies the chain rule with respect to the packed log variables.

The distinction is worth repeating because it prevents a common source of confusion:

- `Physics` writes the equations in the physically natural variables,
- `Methods` explains the packed ASTRA solve basis,
- and the Jacobian must be taken with respect to the packed basis, not the textbook variables.

That is why a derivative like $\partial P / \partial T$ is physically meaningful but not yet solver-ready. ASTRA still needs the chain-rule conversion to $\partial P / \partial \log T$ before the Jacobian entry matches the actual Newton unknown vector.

## Numerical realization in ASTRA

The methods pages describe how this physics becomes code:

- [From Equations to Residual](../methods/from-equations-to-residual.md)
- [Residual Assembly](../methods/residual-assembly.md)
- [Jacobian Construction](../methods/jacobian-construction.md)
- [Linear Solves and Scaling](../methods/linear-solves-and-scaling.md)
- [Boundary Condition Realization](../methods/boundary-condition-realization.md)

## What is deferred

Real EOS tables, opacity tables, real MLT, composition transport, and production evolution algorithms are all deferred from the active solver today. ASTRA's active analytical path now includes `eps_grav` and `eps_nu` in the luminosity equation, while weak screening, triple-alpha, degeneracy, and Coulomb terms remain implemented but default-off. The convection docs now also distinguish clearly between the code-backed criterion hook, the canonical Bohm-Vitense local MLT target, and the later Ledoux-ready / mixing-ready growth path. This page is a map of the classical baseline only, so future contributors can tell the difference between an implemented closure, a flag-gated staged option, and a planned capability.

## Physics handbook checklist

This section is ASTRA's internal QA surface for the Physics overview: what is conceptually established, what is already documented explicitly, and what still needs source-backed or implementation-backed follow-through.

### Conceptual architecture

- [x] Continuous-equation ownership is explicitly separated from numerical ownership.
- [x] The four classical structure equations are named and cross-linked to their detailed pages.
- [x] The page distinguishes `Physics` responsibilities from `Methods` responsibilities.
- [x] The packed-variable discussion points readers back to [Methods](../methods/overview.md) instead of confusing continuous and discrete equations.

### Current implementation coverage

- [x] The staged analytical EOS, opacity, nuclear, and convection closures are stated explicitly.
- [x] Current boundary-condition treatment is stated explicitly.
- [x] The current solve-variable basis is documented explicitly.
- [ ] Every linked closure page currently documents implementation status with equal completeness.

### Validation and source coverage

- [ ] Each major closure page includes source-backed physics references.
- [ ] Each major closure page distinguishes implemented physics from deferred production-grade physics.
- [x] The overview page is backed by consistent detailed pages for stellar structure, EOS, opacity, nuclear, convection, and boundary conditions.
- [ ] Equation-to-implementation consistency has been checked across `Physics` and `Methods` pages.

### Open documentation / physics gaps

- [ ] Real EOS tables are still deferred.
- [ ] Real opacity tables are still deferred.
- [ ] Real MLT is still deferred.
- [ ] Composition transport and evolutionary algorithms are deferred.
- [ ] Section-wide source-backed validation and implementation checklists are not yet complete.
