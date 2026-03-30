# Coupled Problem

The four classical structure equations do not solve separately. They form one nonlinear boundary-value problem, because each equation depends on variables supplied by the others.

## Continuous system

The classical system is

$$
\frac{dr}{dm} = \frac{1}{4 \pi r^2 \rho}, \quad
\frac{dP}{dm} = -\frac{G m}{4 \pi r^4}, \quad
\frac{dL}{dm} = \varepsilon_\mathrm{nuc}, \quad
\frac{dT}{dm} = -\frac{G m T}{4 \pi r^4 P} \nabla
$$

Those equations are coupled through the EOS, opacity, and nuclear closures.

## Current ASTRA implementation

ASTRA assembles the system as one residual vector with center rows, interior blocks, and surface rows. The current placeholder closures are still in place:

- ideal gas plus radiation EOS
- toy Kramers-like opacity
- toy pp-inspired heating
- radiative-gradient transport hook

That means ASTRA is solving the correct *shape* of the classical problem, but not yet with production microphysics.

## Numerical realization in ASTRA

The coupled residual is assembled in [Residual Assembly](../../methods/residual-assembly.md), linearized in [Jacobian Construction](../../methods/jacobian-construction.md), and solved with a Newton loop described in [Nonlinear Newton and Backtracking](../../methods/nonlinear-newton-and-backtracking.md). The system is a true boundary-value problem, so the Jacobian matters as much as the equations themselves.

## What is deferred

The current page is intentionally narrow. It does not claim a finished solar model, a full atmosphere closure, or a mature evolution solver. It explains why the classical ASTRA lane must be solved globally and why the central state variables are determined by the boundary conditions rather than supplied as inputs.

