# Boundary Conditions

Boundary conditions close the global stellar solve. They are not an afterthought: they set the inner asymptotics and the outer matching that make the classical boundary-value problem well posed.

At the center, spherical geometry forces regularity conditions because the naive differential form becomes singular as $r \to 0$. At the surface, the code needs some explicit outer closure so the global system has a finite edge.

That is the physical reason boundary conditions matter. The numerical reason is just as important: poor boundary ownership can make a formally correct interior discretization converge badly or converge to the wrong family of solutions.

## Continuous boundary story

Near the center, symmetry requires the solution to stay regular rather than diverge. In practice that means the innermost radius and luminosity must behave like leading-order series quantities, not like generic interior unknowns. The center is therefore a special asymptotic limit, not merely "the first cell."

At the surface, the continuous stellar-structure equations need a matching condition to some outer-layer or atmosphere model. Production stellar codes often use atmosphere integrations, optical-depth conditions, or tabulated surface relations. ASTRA now owns a staged outer atmosphere closure, and the current implementation uses a one-sided Phase 2 `T(\tau)` match-point reconstruction at the Eddington photosphere, with the outer-cell temperature bridged inward by the local half-cell transport offset rather than by a direct deeper-atmosphere continuation.

## Current ASTRA implementation

ASTRA currently uses center asymptotic targets for radius and luminosity, plus a one-sided outer atmosphere closure for radius, luminosity, temperature, and pressure. The center closure follows the leading-order series form, and the surface closure is intentionally lightweight but physically meaningful.

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

The center rows are assembled in [Residual Assembly](../methods/residual-assembly.md) through the boundary helper layer, and the solver-side interpretation is described in [Boundary Condition Realization](../methods/boundary-condition-realization.md). The atmosphere page [Atmosphere and Photosphere](atmosphere-and-photosphere.md) explains the current Phase 2 outer closure in more detail.

Boundary rows own the edge equations of the global residual, but they do not own EOS, opacity, or atmosphere microphysics internals. That ownership split matters because it keeps the boundary contract narrow: the boundary layer sets edge equations, while the constitutive physics still lives in its own modules.

## Boundary validity checks

The current boundary contract is acceptable when:

- the center targets remain well scaled as the inner mass cell shrinks,
- the outer closure returns thermodynamically admissible surface values,
- the boundary rows do not dominate the residual only because of unit or scale mismatch,
- and converged solutions are not hypersensitive to the exact outer attachment choice.

The 2026-03-30 transport-family validation bundle says the boundary story is mixed rather than purely outer-boundary-local: `interior_transport` dominates the default-12 and larger-cell runs, while `outer_transport` still dominates the smallest `n_cells = 6, 8` cases. That is a boundary-sensitive signal, but it is not a proof that the outer edge alone is the bottleneck.

## What is deferred

Phase 3 richer atmosphere options and a more explicit benchmark campaign are deferred. ASTRA currently needs the surface to be explicit, numerically stable, and scientifically legible, not yet astrophysically complete.

The approved next step is to keep the current outer radius and luminosity target rows while the surface thermodynamic rows use the shared outer match-point helper layer, the surface pressure scale uses the shared outer match-point pressure scale, and the outer transport row remains one-sided to the photospheric face. That keeps the atmosphere question separate from the larger future question of whether ASTRA should continue to target both outer `R` and `L` in the long run.

## Implementation checklist

- [x] The center asymptotic targets for radius and luminosity are written explicitly.
- [x] The page states that the center is a regularity problem, not an ordinary interior stencil.
- [x] The surface closure is identified as a Phase 2 atmosphere reconstruction rather than a guessed boundary.
- [x] The one-sided `T(\tau)` atmosphere reconstruction is recorded as current behavior.
- [ ] The exact sign and indexing conventions for all boundary residual rows are cross-checked against the methods page and tests.

## MESA parity checklist

- [ ] The nearest MESA comparison remains explicitly labeled as center-boundary analogy or partial parity rather than full boundary equivalence.
- [ ] Any future claim about surface-boundary parity is backed by specific atmosphere or boundary files from the local MESA mirror.

## Production-grade status checklist

- [x] Replace the provisional surface density/temperature guesses with a physically justified outer closure.
- [x] The approved one-sided `T(\tau)` reconstruction is in place.
- [ ] Demonstrate that the atmosphere closure supports robust convergence across more than the current narrow bootstrap basin.
