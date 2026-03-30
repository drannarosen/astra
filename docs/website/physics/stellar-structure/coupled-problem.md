# Coupled Problem

The four classical structure equations do not solve separately. They form one nonlinear boundary-value problem, because each equation depends on variables supplied by the others.

In plain language, stellar structure is a global balance problem. Density affects geometry, geometry affects gravity, gravity affects pressure support, pressure, opacity, and luminosity affect the temperature gradient, and temperature and composition affect the local source terms. Changing one part of the solution changes the others, which is why the star has to be solved as one coupled system.

## Continuous system

The classical system in enclosed-mass coordinate is

$$
\begin{aligned}
\text{Mass conservation:} \quad & \frac{dr}{dm} = \frac{1}{4 \pi r^2 \rho} \\
\text{Hydrostatic equilibrium:} \quad & \frac{dP}{dm} = -\frac{G m}{4 \pi r^4} \\
\text{Energy generation:} \quad & \frac{dL}{dm} = \varepsilon_\mathrm{nuc} + \varepsilon_\mathrm{grav} - \varepsilon_\nu \\
\text{Energy transport:} \quad & \frac{dT}{dm} = -\frac{G m T}{4 \pi r^4 P} \nabla
\end{aligned}
$$

This is a coupled system because each equation needs quantities controlled by the others. Mass conservation depends on density. Hydrostatic equilibrium depends on radius through the gravity term. Energy generation depends on the local source terms. Energy transport depends on pressure, opacity, luminosity, and the temperature gradient. Closures such as the EOS, opacity law, and source prescriptions tie those dependencies together into one nonlinear system.

This is also a boundary-value problem because the center and surface conditions help determine the entire interior solution. The central and surface constraints are not optional add-ons. They are part of what fixes the interior state, which is why the system cannot be solved shell by shell as four independent updates.

## Current ASTRA implementation

ASTRA assembles the system as one residual vector with center rows, interior blocks, and surface rows. The current staged analytical closures are the current placeholder closures for the bootstrap lane:

- analytical gas plus radiation EOS
- analytical opacity components
- analytical PP-plus-CNO heating plus source-decomposed `eps_grav` and `eps_nu`
- radiative-gradient transport hook

That means ASTRA is solving the correct *shape* of the classical problem, but not yet with production microphysics. The coupled-system structure is already there, and the luminosity row now owns an assembled `eps_nuc + eps_grav - eps_nu` source term. Gravothermal release is evolution-owned because it depends on previous accepted thermodynamic history and EOS response terms, while screening-enabled burning and richer EOS corrections remain flag-gated rather than default-on. Composition evolution remains deferred.

## Numerical realization in ASTRA

The coupled residual is assembled in [Residual Assembly](../../methods/residual-assembly.md), linearized in [Jacobian Construction](../../methods/jacobian-construction.md), and solved with a Newton loop described in [Nonlinear Newton and Backtracking](../../methods/nonlinear-newton-and-backtracking.md). One residual vector and one Jacobian matrix are the numerical expression of the fact that the equations must be solved together.

## What is deferred

The current page is intentionally narrow. It does not claim a finished solar model, a full atmosphere closure, or a mature evolution solver. It explains why the classical ASTRA lane must be solved globally and why the central state variables are determined by the boundary conditions rather than supplied as inputs.

## Internal QA and open checks

### Conceptual architecture

- [x] The page states clearly that the four equations form one coupled boundary-value problem.
- [x] The equations are presented in a named equation array.
- [x] The page distinguishes continuous physics from numerical realization.
- [x] The page explains why closures make the system nonlinear.

### Current implementation coverage

- [x] ASTRA assembles one residual vector with center, interior, and surface rows.
- [x] ASTRA currently uses staged analytical EOS, opacity, nuclear, and transport closures.
- [x] ASTRA currently implements a source-decomposed luminosity row with evolution-owned `eps_grav` and staged `eps_nu`.
- [x] The coupled-system structure is present even though the microphysics is still bootstrap-level.

### Validation and comparison status

- [ ] The coupled classical system is benchmarked against a solar-structure reference artifact.
- [ ] Cross-equation consistency has been checked against an end-to-end hydrostatic model.
- [ ] The role of deferred `eps_grav` and `eps_nu` terms is documented with validation artifacts.
- [ ] The boundary-value solve is validated strongly enough to serve as a production classical reference lane.

### Open risks / next checks

- [ ] Closure simplicity may hide coupling pathologies that appear with realistic microphysics.
- [ ] Surface boundary treatment may still limit the useful convergence basin.
- [ ] The current classical lane is not yet validated strongly enough for formulation-comparison claims.
- [ ] Production-grade coupling between source terms, transport, and evolving composition is still deferred.
