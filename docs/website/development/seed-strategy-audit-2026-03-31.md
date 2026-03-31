# Seed Strategy Audit 2026-03-31

Artifact bundle: `artifacts/validation/2026-03-31-seed-strategy-audit`

This page records ASTRA's first seed-family comparison after the focused
surface-pressure audit. The compared seed labels are `bootstrap_default` and
`convective_pms_like`.

## What was compared

- `bootstrap_default`: ASTRA's current geometry-consistent, source-matched,
  surface-anchored bootstrap seed.
- `convective_pms_like`: an internal, diagnostic-only PMS-like seed with lower
  central temperature, near-adiabatic thermodynamic shape, and
  contraction-powered luminosity scaling.

Both lanes use the same mass grid, the same `StellarModel` ownership contract,
the same surface family definition, and the same focused four-case audit shape:
`default-12` plus three `1.0e-6` perturbation cases.

## Measured result

`bootstrap_default` preserves the same sharp surface-pressure bridge story seen
in the boundary audit. In all four focused payloads,
`accepted_surface_pressure_bridge_dominant = true`,
`accepted_outer_boundary_dominant_family = surface_pressure`,
`converged = false`, and `used_regularized_fallback = true`.

`convective_pms_like` does not improve the current basin in this slice. On
`convective_pms_like-default-12`:

- `initial_merit = 1.4652955562551198e83`,
- `final_merit = 3.228091380703186e81`,
- `accepted_dominant_family = center`,
- `accepted_dominant_surface_family = surface_pressure`,
- `accepted_outer_boundary_dominant_family = outer_transport`,
- and `accepted_surface_pressure_bridge_dominant = false`.

For comparison, `bootstrap_default-default-12` has:

- `initial_merit = 7.606095159786209`,
- `final_merit = 7.137553468301087`,
- `accepted_dominant_family = surface`,
- `accepted_dominant_surface_family = surface_pressure`,
- `accepted_outer_boundary_dominant_family = surface_pressure`,
- and `accepted_surface_pressure_bridge_dominant = true`.

## Interpretation

This is a discrimination slice, not a canonical-lane promotion. The measured
bundle says the current diagnostic PMS-like construction does not yet widen the
live convergence basin. It changes the owner story, but it changes it in the
wrong direction for this fixed static solve: the dominant family moves to the
center while the solve still fails.

That means saved ZAMS remains a later control lane only, not the current
science-lane seed answer. The canonical science lane remains PMS-first, but it
still needs the missing PMS architecture pieces that this slice intentionally
did not implement: relaxation, accepted hydrostatic handoff, and evolutionary
landmarks such as ZAMS detection.

## What this supports

- keep `bootstrap_default` as the public default seed for now,
- keep `convective_pms_like` internal and diagnostic-only,
- keep saved ZAMS remains a later control lane only,
- and keep the canonical science lane remains PMS-first.

## What this does not prove

- that ASTRA's current bootstrap seed is scientifically adequate,
- that PMS startup should be abandoned,
- or that the remaining live blocker is definitely seed-free rather than a
  coupled seed/boundary interaction.
