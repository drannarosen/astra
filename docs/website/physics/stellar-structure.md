# Stellar Structure

The classical 1D stellar-structure problem is a single coupled boundary-value problem in the enclosed-mass coordinate. It combines geometry, force balance, source balance, and energy transport into one nonlinear solve.

This page owns the continuous-equation specification. The companion [Methods](../methods/index.md) pages own the discrete residual and Jacobian specification.

If you are new to stellar numerics, it helps to read this page as a translation table. Each equation is a compact statement about what a star must do everywhere at once. The methods pages later explain how ASTRA converts those statements into finite residual rows, but the continuous equations come first because they define what the code is trying to be faithful to.

## What the coupled problem does

The four structure equations are:

- shorthand `dr/dm` for mass conservation and shell geometry: $\frac{dr}{dm}$
- shorthand `dP/dm` for hydrostatic support: $\frac{dP}{dm}$
- shorthand `dL/dm` for energy generation: $\frac{dL}{dm}$
- shorthand `dT/dm` for energy transport: $\frac{dT}{dm}$

ASTRA now arranges those equations on a staggered mesh with face-centered radius and luminosity, and cell-centered density and temperature. That is the classical baseline lane, not a finished stellar-evolution package.

In the continuous theory, those equations are usually written in physical variables. In the actual nonlinear solve, ASTRA updates mostly logarithmic state variables,

$$
x = \left(\log r_{i+1/2},\; L_{i+1/2},\; \log T_i,\; \log \rho_i \right),
$$

because $r$, $T$, and $\rho$ span extreme dynamic ranges and must remain positive. That means the numerics layer must distinguish carefully between:

- the physical equations, written in $r$, $P$, $L$, $T$, and $\rho$,
- and the solver derivatives, taken with respect to $\log r$, $\log T$, and $\log \rho$.

## Continuous equations in mass coordinate

For a static, spherically symmetric, non-rotating star written in enclosed baryonic mass $m$, the classical structure equations are

$$
\frac{dr}{dm} = \frac{1}{4 \pi r^2 \rho},
$$

$$
\frac{dP}{dm} = -\frac{G m}{4 \pi r^4},
$$

$$
\frac{dL}{dm} = \varepsilon_\mathrm{nuc} + \varepsilon_\mathrm{grav} - \varepsilon_\nu,
$$

$$
\frac{dT}{dm} = -\frac{G m T}{4 \pi r^4 P} \nabla,
\qquad
\nabla \equiv \frac{d \ln T}{d \ln P}.
$$

These are the equations ASTRA is trying to represent. They are continuous physical statements, not yet ASTRA row formulas. The first equation tells us how geometry and density determine shell thickness. The second says pressure must decline outward strongly enough to support the enclosed mass. The third is the energy-accounting equation. The fourth says the temperature gradient depends on how energy is transported.

The key insight for solver developers is that these equations are tightly coupled through closures. Pressure is not an independent free function; it comes from the EOS. The transport gradient is not an independent free function either; it depends on opacity, luminosity, thermodynamics, and eventually convection physics. That is why even a "simple" stellar model is already a nonlinear coupled system.

## What the closures must provide

The continuous equations are not closed until ASTRA specifies at least:

- an equation of state supplying $P(\rho, T, X_i)$ and its derivatives,
- an opacity law supplying $\kappa(\rho, T, X_i)$ and its derivatives,
- an energy-source model supplying $\varepsilon_\mathrm{nuc}$ and eventually $\varepsilon_\mathrm{grav}$ and $\varepsilon_\nu$,
- a transport prescription supplying $\nabla$.

In the current classical lane, ASTRA uses an ideal-gas-plus-radiation EOS, a toy Kramers opacity, a toy pp-like nuclear source, and a radiative transport gradient. Those choices are intentionally small enough that contributors can inspect every term end to end. The point of the current lane is not production microphysics richness. It is explicit ownership.

## Continuous equations versus ASTRA residual equations

This distinction is the central contract of the handbook.

The continuous equations above are written in differential form. ASTRA does not solve them directly. Instead, it solves discrete residual equations on a staggered mesh with face-centered radius and luminosity and cell-centered temperature and density. The discrete equations are defined in [Residual Assembly](../methods/residual-assembly.md).

That separation matters for scientific correctness. A code can quote the right textbook equation and still implement the wrong sign, the wrong owner, the wrong variable basis, or the wrong boundary semantics. ASTRA therefore treats agreement between `Physics` and `Methods` as a contract, not as a stylistic preference.

## Current ASTRA implementation

The current residual has one geometric row, one hydrostatic row, one luminosity row, and one transport row per interior zone, plus center and surface boundary rows. The interior rows are built from the current toy EOS, opacity, and nuclear closures, so the solver can exercise the full residual chain before the microphysics grows up.

That means the code is already solving the right *kind* of nonlinear system, but still with intentionally simple closures:

- shell-volume geometry in the mass row
- ideal-gas-plus-radiation pressure in the hydrostatic row
- toy pp-like heating in the luminosity row
- radiative-gradient transport in the temperature row

The full classical source balance is broader than the current bootstrap implementation. In standard stellar structure, the luminosity equation includes nuclear heating, gravothermal release, and neutrino losses. ASTRA currently implements only the nuclear term in the residual, while documenting the full energy budget explicitly so later extensions have a clear owner.

## Numerical realization in ASTRA

The residual assembly lives in [Residual Assembly](../methods/residual-assembly.md). The solver boundary and variable ownership live in [From Equations to Residual](../methods/from-equations-to-residual.md) and [Staggered Mesh and State Layout](../methods/staggered-mesh-and-state-layout.md). Jacobian quality is tracked in [Jacobian Construction](../methods/jacobian-construction.md).

## What is deferred

The current page is the classical baseline only. A validated solar model, realistic EOS/opacity tables, MLT, composition transport, PMS evolution, and Entropy-DAE all remain deferred until the classical residual is numerically trustworthy.

## Implementation checklist

- [x] The continuous four-equation stellar-structure system is written explicitly in mass coordinate.
- [x] The page distinguishes continuous equations from ASTRA's residual equations.
- [x] The log-variable solve basis is described as a numerical choice, not as a rewrite of the physics.
- [ ] Each detailed subpage verifies its sign convention against the current ASTRA implementation.

## Validation checklist

- [ ] The equations on this page are cross-checked against an end-to-end classical hydrostatic benchmark, not only internal ASTRA consistency.
- [ ] The current implementation is benchmarked against at least one solar-structure reference artifact.
- [ ] The deferred terms in the luminosity equation are accompanied by code or validation artifacts before this page can claim production-grade status.

## Open-risk checklist

- [x] The page states that ASTRA currently owns only the classical bootstrap lane.
- [x] The page states that closures remain intentionally simple.
- [ ] The surface closure and convergence basin are upgraded enough that this page can describe the classical lane as numerically robust rather than pedagogically explicit.
