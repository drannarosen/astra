# Residual Assembly

ASTRA assembles the residual vector in physical order, not in whatever order happens to be convenient for a matrix buffer.

This page is the discrete-equation specification for the current classical solve.

If the `Physics` pages tell you what the star should satisfy in continuous form, this page tells you exactly what ASTRA is currently asking the Newton solve to drive to zero. It is therefore the canonical residual-spec page, not merely a commentary page.

## Row ordering

The current residual has three top-level groups:

- center rows,
- interior blocks,
- surface rows.

The center rows enforce the asymptotic inner radius and luminosity targets. Each interior block then contributes four rows:

1. geometry,
2. hydrostatic balance,
3. luminosity balance,
4. transport.

The surface rows enforce the Phase 1 atmosphere closure. Radius and luminosity targets stay in place, the temperature row matches `T_eff`, the pressure row matches the photospheric pressure scale, and the final transport row becomes one-sided at the outer edge.

## Normative interior residual contract

For each interior block $k$, ASTRA currently defines the residual rows as

$$
R_{\mathrm{geom},k} =
V_\mathrm{shell}(r_k, r_{k+1}) - \frac{dm_k}{\rho_k},
$$

The literal row label `R_{\mathrm{geom},k}` denotes the geometry equation for block $k$.

$$
R_{\mathrm{hse},k} =
P_{k+1} - P_k + \frac{G m_{k+1} dm_k}{4 \pi r_{k+1}^4},
$$

$$
R_{L,k} =
L_{k+1} - L_k - dm_k \, \varepsilon_{\mathrm{nuc},k},
$$

$$
R_{T,k} =
\log T_{k+1} - \log T_k + \nabla_k \left(\log P_{k+1} - \log P_k\right).
$$

Those equations are the current ASTRA implementation contract. If the code changes any sign, indexing convention, or owner in those rows, the methods docs should change in the same slice.

The most important interpretation detail is that these are residual equations, not copied textbook ODEs. The geometry row compares a shell-volume expression to $dm/\rho$. The transport row is already written in log form because ASTRA solves $\log T$, not $T$, and because the radiative-gradient helper is currently expressed through logarithmic pressure differences.

## What each interior block means

The row family mirrors the current `src/numerics/residuals.jl` implementation:

- geometry compares shell volume to `dm / rho`,
- hydrostatic balance compares adjacent-cell pressure plus gravity,
- luminosity balance currently subtracts $dm \, \varepsilon_\mathrm{nuc}$,
- transport uses the log-form radiative gradient row.

For the continuous physics behind those rows, see [Mass Conservation](../physics/stellar-structure/mass-conservation.md), [Hydrostatic Equilibrium](../physics/stellar-structure/hydrostatic-equilibrium.md), [Energy Generation](../physics/stellar-structure/energy-generation.md), and [Energy Transport](../physics/stellar-structure/energy-transport.md).

The full classical luminosity equation should eventually carry

$$
\frac{dL}{dm} = \varepsilon_\mathrm{nuc} + \varepsilon_\mathrm{grav} - \varepsilon_\nu,
$$

but the current ASTRA residual only owns the nuclear term. That means the residual is already source-decomposed in the energy equation in spirit, but only partially in the bootstrap implementation. The current closure stack is still toy physics; the row order and ownership boundaries are what matter here.

The current surface formulas are:

$$
R_{\mathrm{surf},r} = r_\mathrm{surf} - r_\mathrm{target},
$$

$$
R_{\mathrm{surf},L} = L_\mathrm{surf} - L_\mathrm{target},
$$

$$
R_{\mathrm{surf},T} = \log T_\mathrm{outer} - \log T_\mathrm{eff},
$$

$$
R_{\mathrm{surf},P} = P_\mathrm{EOS}(\rho_\mathrm{outer}, T_\mathrm{outer}) - P_\mathrm{ph}.
$$

The outer transport row is one-sided and uses the photospheric target instead of the generic interior stencil. That keeps the outer edge boundary-aware without adding a new atmosphere state block.

It is useful to spell out exactly what is and is not true today:

- ASTRA already owns a real luminosity-balance row with a physically meaningful sign convention.
- ASTRA does not yet own the full classical source decomposition in that row.
- ASTRA already owns a transport row in solver basis.
- ASTRA does not yet own a finished convection-aware transport closure.

## Why this page exists

This is the canonical map from equation language to the discrete solve. If a future developer wants to know which residual row owns a bug, this page should answer the question before they start reading code.

The continuous counterparts live in:

- [Mass Conservation](../physics/stellar-structure/mass-conservation.md)
- [Hydrostatic Equilibrium](../physics/stellar-structure/hydrostatic-equilibrium.md)
- [Energy Generation](../physics/stellar-structure/energy-generation.md)
- [Energy Transport](../physics/stellar-structure/energy-transport.md)

## Implementation checklist

- [x] The center, interior, and surface row grouping is explicit.
- [x] The interior rows are written with exact current ASTRA signs.
- [x] The current source decomposition of the luminosity row is stated honestly.
- [x] The center and surface row formulas are expanded here with the same level of detail as the interior block.

## Validation checklist

- [ ] A benchmark artifact verifies the geometry, hydrostatic, luminosity, and transport rows against an accepted model, not only code self-consistency.
- [ ] Residual-family diagnostics exist that can be compared before and after major solver changes.

## Deferred-scope checklist

- [x] `eps_grav` is not yet part of `R_{L,k}`.
- [x] `eps_nu` is not yet part of `R_{L,k}`.
- [x] The transport row is still radiative-only in the current classical lane.
