# Boundary Conditions

Boundary conditions close the global stellar solve. They are not an afterthought: they set the inner asymptotics and the outer matching that make the classical boundary-value problem well posed.

At the center, spherical geometry forces regularity conditions because the naive differential form becomes singular as $r \to 0$. At the surface, the code needs some explicit outer closure so the global system has a finite edge.

## Current ASTRA implementation

ASTRA currently uses center asymptotic targets for radius and luminosity, plus provisional surface guesses for radius, luminosity, temperature, and density. The center closure follows the leading-order series form, and the surface closure is intentionally lightweight.

The current center targets are:

- `r_inner = (3 m_inner / (4 pi rho_c))^(1/3)`
- `L_inner = m_inner * epsilon_nuc`

Those are the rows that replaced the older fragile center closure.

## Numerical realization in ASTRA

The center rows are assembled in [Residual Assembly](../methods/residual-assembly.md) through the boundary helper layer, and the solver-side interpretation is described in [Boundary Condition Realization](../methods/boundary-condition-realization.md). The surface guesses are still provisional and remain part of the bootstrap lane only.

## What is deferred

Real atmosphere fitting, solar-calibrated outer layers, and a finished surface closure are deferred. ASTRA currently needs the surface to be explicit and numerically stable, not astrophysically complete.
