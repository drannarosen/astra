# Physics

ASTRA's physics pages explain the continuous stellar-structure model before the discretization details begin. The goal is to keep the science legible for students and the implementation honest for developers: what equations are solved, what closures are supplied, and what is still stubbed.

## Structure equations

The classical baseline is the coupled four-equation problem in enclosed mass:

- mass conservation: `dr/dm`
- hydrostatic equilibrium: `dP/dm`
- energy generation: `dL/dm`
- energy transport: `dT/dm`

Those equations appear in [Stellar Structure](stellar-structure.md), and ASTRA currently solves their discrete residual form on a staggered face/cell mesh.

## Constitutive physics

The structure equations are not closed until we choose an equation of state, an opacity law, a nuclear heating law, and a transport closure. ASTRA's bootstrap lane currently uses placeholder physics:

- [Equation of State](eos.md): ideal gas plus radiation
- [Opacity](opacity.md): toy Kramers-like opacity
- [Nuclear Energy Generation](nuclear.md): toy pp-inspired heating
- [Convection](convection.md): criterion hook only

These pages explain the physics and state plainly what ASTRA actually computes today.

## Boundary conditions

The center and surface close the global solve. The center uses asymptotic series targets for the innermost face, and the surface uses provisional guessed outer conditions. See [Boundary Conditions](boundary-conditions.md) for the current closure and [Methods](../methods/index.md) for how those conditions enter the residual.

## Current ASTRA implementation

ASTRA currently solves a classical residual with `log(radius)`, `log(temperature)`, and `log(density)` as the thermodynamic/geometry unknowns, while keeping luminosity in raw cgs `erg/s`. The result is a bootstrap classical solve, not a production stellar model, but the ownership of each quantity is now explicit enough that the equations can be hardened step by step.

## Numerical realization in ASTRA

The methods pages describe how this physics becomes code:

- [From Equations to Residual](../methods/from-equations-to-residual.md)
- [Residual Assembly](../methods/residual-assembly.md)
- [Jacobian Construction](../methods/jacobian-construction.md)
- [Linear Solves and Scaling](../methods/linear-solves-and-scaling.md)
- [Boundary Condition Realization](../methods/boundary-condition-realization.md)

## What is deferred

Real EOS tables, real opacity tables, real MLT, composition transport, and evolutionary algorithms are all deferred. This page is a map of the classical baseline only, so future contributors can tell the difference between an implemented closure and a planned one.
