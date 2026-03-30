# Boundary Conditions

Boundary conditions close the global stellar solve. They are not an afterthought: they set the inner asymptotics and the outer matching that make the classical boundary-value problem well posed.

At the center, spherical geometry forces regularity conditions because the naive differential form becomes singular as $r \to 0$. At the surface, the code needs some explicit outer closure so the global system has a finite edge.

That is the physical reason boundary conditions matter. The numerical reason is just as important: poor boundary ownership can make a formally correct interior discretization converge badly or converge to the wrong family of solutions.

## Continuous boundary story

Near the center, symmetry requires the solution to stay regular rather than diverge. In practice that means the innermost radius and luminosity must behave like leading-order series quantities, not like generic interior unknowns. The center is therefore a special asymptotic limit, not merely "the first cell."

At the surface, the continuous stellar-structure equations need a matching condition to some outer-layer or atmosphere model. Production stellar codes often use atmosphere integrations, optical-depth conditions, or tabulated surface relations. ASTRA now owns a staged outer atmosphere closure, but it is still a Phase 1 representative-cell approximation rather than a finished atmosphere module.

## Current ASTRA implementation

ASTRA currently uses center asymptotic targets for radius and luminosity, plus an Eddington-grey outer atmosphere closure for radius, luminosity, temperature, and pressure. The center closure follows the leading-order series form, and the surface closure is intentionally lightweight but physically meaningful.

The current center targets are:

$$
r_\mathrm{inner} = \left(\frac{3 m_\mathrm{inner}}{4 \pi \rho_c}\right)^{1/3}
$$

$$
L_\mathrm{inner} = m_\mathrm{inner} \, \varepsilon_\mathrm{nuc}
$$

Those are the rows that replaced the older fragile center closure.

The numerical motivation for this choice is worth making explicit. A center row built from direct subtraction of nearly equal shell volumes or from an imposed `L(0)=0` without asymptotic scaling can create poor conditioning exactly where the geometry is already delicate. ASTRA's current center closure instead uses physically motivated target values that remain well scaled as the innermost mass shrinks.

## Numerical realization in ASTRA

The center rows are assembled in [Residual Assembly](../methods/residual-assembly.md) through the boundary helper layer, and the solver-side interpretation is described in [Boundary Condition Realization](../methods/boundary-condition-realization.md). The atmosphere page [Atmosphere and Photosphere](atmosphere-and-photosphere.md) explains the current Phase 1 outer closure in more detail.

## What is deferred

Phase 2 `T(\tau)` matching, real atmosphere tables, and a more explicit photospheric reconstruction are deferred. ASTRA currently needs the surface to be explicit, numerically stable, and scientifically legible, not yet astrophysically complete.

## Implementation checklist

- [x] The center asymptotic targets for radius and luminosity are written explicitly.
- [x] The page states that the center is a regularity problem, not an ordinary interior stencil.
- [x] The surface closure is identified as a Phase 1 atmosphere approximation rather than a finished atmosphere model.
- [ ] The exact sign and indexing conventions for all boundary residual rows are cross-checked against the methods page and tests.

## MESA parity checklist

- [ ] The nearest MESA comparison remains explicitly labeled as center-boundary analogy or partial parity rather than full boundary equivalence.
- [ ] Any future claim about surface-boundary parity is backed by specific atmosphere or boundary files from the local MESA mirror.

## Production-grade status checklist

- [x] Replace the provisional surface density/temperature guesses with a physically justified outer closure.
- [ ] Demonstrate that the atmosphere closure supports robust convergence across more than the current narrow bootstrap basin.
