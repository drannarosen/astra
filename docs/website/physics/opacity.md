# Opacity

Opacity controls how easily radiation carries energy through a stellar layer. In the classical ASTRA lane, it is still a toy closure, but it now feeds the real residual and Jacobian rather than living only in a test fixture.

## Current ASTRA implementation

ASTRA currently uses a toy Kramers-style law:

`kappa = 4.0e25 * max(Z, 1.0e-3) * rho * T^-3.5`

That choice is deliberately simple. It gives the solver a smooth, differentiable opacity with explicit density and temperature dependence, which is enough to exercise the transport row and the Jacobian audit.

## Numerical realization in ASTRA

Opacity enters the radiative-gradient helper in [Residual Assembly](../methods/residual-assembly.md) and contributes density and temperature derivatives in [Jacobian Construction](../methods/jacobian-construction.md). The method pages explain how the current fallback rows and scaling work around that closure.

## What is deferred

Real opacity tables, low-temperature molecular physics, conductive opacity, and blend hierarchies are deferred. The current page should be read as the exact placeholder used today, not as a promise about ASTRA's eventual opacity stack.
