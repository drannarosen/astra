# Hydrostatic Equilibrium

Hydrostatic equilibrium is the force-balance equation that keeps a star from collapsing. It states that outward pressure support balances the inward pull of gravity in mass coordinate.

The shorthand form is `dP/dm`, which is the exact structural derivative discussed in the classical baseline pages.

## Continuous equation

$$
\frac{dP}{dm} = -\frac{G m}{4 \pi r^4}
$$

Here $P$ is pressure, $G$ is the gravitational constant, $m$ is enclosed mass, and $r$ is the local radius. The negative sign means pressure must fall outward to support the overlying mass.

## Current ASTRA implementation

ASTRA currently evaluates pressure from the EOS at adjacent cells and forms the hydrostatic residual as a pressure difference plus the gravitational term:

$$
P_{k+1} - P_k + \frac{G m_{k+1} dm_k}{4 \pi r_{k+1}^4} = 0
$$

That is the `hydrostatic` row in `src/numerics/residuals.jl`. Pressure is not a solve-owned variable; it is supplied by the EOS closure in `src/numerics/structure_equations.jl`.

## Numerical realization in ASTRA

The pressure support term is assembled in [Residual Assembly](../../methods/residual-assembly.md), and the EOS dependency is described in [Equation of State](../eos.md). Jacobian sensitivity for the hydrostatic row is tracked in [Jacobian Construction](../../methods/jacobian-construction.md).

## What is deferred

The current hydrostatic row is still part of the classical baseline only. Relativistic corrections, rotation, and time-dependent momentum balance are deferred. ASTRA currently solves the static hydrostatic balance, not a dynamical stellar flow problem.
