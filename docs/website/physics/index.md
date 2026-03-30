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

The structure equations are not closed until we choose an equation of state, an opacity law, a nuclear heating law, and a transport closure. ASTRA's bootstrap lane currently uses placeholder physics:

- [Equation of State](eos.md): ideal gas plus radiation
- [Opacity](opacity.md): toy Kramers-like opacity
- [Nuclear Energy Generation](nuclear.md): toy pp-inspired heating
- [Convection](convection.md): criterion hook only

These pages explain the physics and state plainly what ASTRA actually computes today.

For new contributors, this is one of the most important distinctions in the handbook:

- the structure equations are the universal continuous statements,
- the closure pages explain how ASTRA turns symbols such as $P(\rho, T)$ or $\kappa(\rho, T)$ into actual numbers and derivatives,
- and the methods pages explain how those continuous statements are turned into a nonlinear algebra problem.

## Boundary conditions

The center and surface close the global solve. The center uses asymptotic series targets for the innermost face, and the surface uses provisional guessed outer conditions. See [Boundary Conditions](boundary-conditions.md) for the current closure and [Methods](../methods/index.md) for how those conditions enter the residual.

This matters numerically because the center and surface are exactly where the naive differential forms become least trustworthy. The center is formally singular in several common rearrangements, and the outer boundary is where a stellar interior model must decide how it is being matched to an atmosphere or outer-layer prescription.

## Current ASTRA implementation

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

Real EOS tables, real opacity tables, real MLT, composition transport, and evolutionary algorithms are all deferred. This page is a map of the classical baseline only, so future contributors can tell the difference between an implemented closure and a planned one.

## Physics handbook checklist

- [x] Continuous-equation ownership is explicitly separated from numerical ownership.
- [x] The four classical structure equations are named and cross-linked to their detailed pages.
- [x] The packed-variable story points back to [Methods](../methods/index.md) rather than pretending the continuous equations are already discrete equations.
- [ ] Every closure page documents the exact continuous equation, the current ASTRA implementation, and the deferred production-grade terms with equal detail.
- [ ] Every major page in this section includes source-backed validation and implementation checklists that can be updated as ASTRA grows.
