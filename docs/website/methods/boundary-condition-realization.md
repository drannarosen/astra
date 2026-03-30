# Boundary Condition Realization

ASTRA realizes the boundary conditions as residual rows, not as special-cased solver magic.

This page is the canonical numerical specification for the current boundary rows.

That separation is an architectural choice as much as a numerical one. Once the boundary conditions are written as explicit rows, they can be inspected, differentiated, validated, and compared against MESA or against future ASTRA alternatives without digging through nonlinear-control flow.

## Center asymptotic realization

The inner face uses asymptotic center targets for radius and luminosity:

$$
r_\mathrm{inner} = \left(\frac{3 m_\mathrm{inner}}{4 \pi \rho_c}\right)^{1/3}
$$

$$
L_\mathrm{inner} = m_\mathrm{inner} \, \varepsilon_\mathrm{nuc}
$$

That is the center asymptotic closure ASTRA now solves instead of the older subtractive-cancellation form. The old shell-volume center row and the old `L_face[1] = 0` style behavior were exactly the kind of inner-boundary numerics that could stall the bootstrap solve.

## Normative center-boundary contract

For the current classical lane, the center residual rows are specified as

$$
R_{\mathrm{center},r} = r_1 - \left(\frac{3 m_1}{4 \pi \rho_c}\right)^{1/3},
$$

$$
R_{\mathrm{center},L} = L_1 - m_1 \, \varepsilon_{\mathrm{nuc},c}.
$$

Those are the current ASTRA equations, not merely a design intention.

The row ownership is deliberately simple. The center radius row is owned by geometry plus regularity. The center luminosity row is owned by source accounting at the innermost enclosed mass. That clarity is more important right now than carrying a more ambitious but poorly conditioned center formulation.

## Surface closure

The surface rows now use a one-sided Phase 2 `T(\tau)` atmosphere closure rather than hard guesses. They keep the problem square and numerically stable while giving the outer boundary a physically interpretable temperature and pressure scale.

## Normative surface-boundary contract

For the current classical lane, the outer boundary is closed by four explicit residual rows for:

1. outer radius,
2. outer luminosity,
3. surface temperature matched to the shared outer match-point temperature,
4. surface pressure matched to the shared outer match-point pressure scale.

Those rows are intentionally staged. They are part of the canonical current solve, but they are still a one-sided `T(\tau)` atmosphere approximation rather than a production atmosphere or photosphere specification.

For the physics-side explanation of the photosphere, tau `= 2/3`, and the planned `T(\tau)` path, see [Atmosphere and Photosphere](../physics/atmosphere-and-photosphere.md).

The approved next step is more specific than that short phrase suggests. Phase 2 preserves the current outer radius and luminosity target rows and routes the final transport row and pressure scaling through the same helper layer as the surface match-point reconstruction. In other words, the implementation changes the atmosphere semantics, not the global bootstrap family definition.

## Why this matters

The page exists so future readers can see the boundary conditions as explicit discrete residuals. That makes the center asymptotic choice and the surface closure tradeoff visible instead of hidden inside the solver.

The continuous boundary story is summarized in [Physics: Boundary Conditions](../physics/boundary-conditions.md). For the closest source-backed MESA comparison on center ownership and boundary-side special handling, see [MESA Reference: Boundary Conditions](mesa-reference/boundary-conditions.md).

## Implementation checklist

- [x] The center residual equations are written explicitly.
- [x] The surface closure is identified as explicit and one-sided.
- [x] The page states that these rows are the current ASTRA equations, not only design goals.
- [x] The current surface row formulas are written explicitly.
- [x] The outer transport row and surface pressure scale are recorded as sharing the Phase 2 helper layer.
- [x] The Phase 2 `T(\tau)` path is documented as implemented.

## MESA parity checklist

- [ ] Center-boundary comparisons remain labeled as partial parity or analogy only unless ASTRA matches both ownership and solver semantics.
- [ ] Surface-boundary parity remains unclaimed until the local MESA atmosphere/boundary files are read and cited directly.

## Production-grade status checklist

- [x] Replace the provisional outer rows with a physically motivated surface match.
- [ ] Demonstrate that the atmosphere boundary supports convergence without excessive rejected trials across representative models.
