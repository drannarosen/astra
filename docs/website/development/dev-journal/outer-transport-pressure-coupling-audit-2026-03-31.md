# Outer Transport Pressure Coupling Audit 2026-03-31

Artifact bundle: `artifacts/validation/2026-03-31-outer-transport-pressure-coupling-audit`

Retention status: `current`

This page records the focused control comparison between ASTRA's default outer
transport pressure target and an internal alignment lane that forces the outer
transport row to use the same selected pressure target as the surface-pressure
row.

The literal `outer_transport_pressure_label` in the manifest records which
outer-row pressure target generated each payload.

## What was compared

- `photospheric_face`: the live outer transport row, which still spans pressure
  from the surface cell to the photospheric face.
- `selected_pressure_target`: an internal control lane that aligns the outer
  transport row's pressure target to the same selected target used by the
  surface-pressure row.

Both lanes keep the current bridge pressure closure, the same
`bootstrap_default` seed family, the same `default-12` base problem, and the
same three `1.0e-6` perturbation cases.

## Measured result

The alignment lane changes the numerics materially for `default-12`, but it
does not recover convergence and it does not move the accepted outer-boundary
owner away from `surface_pressure`.

Measured headline facts from the manifest:

- `photospheric_face-default-12`: `converged = false`, `accepted_step_count = 8`,
  `rejected_trial_count = 801`, `initial_merit = 7.606095159786209`,
  `final_merit = 7.137553468301087`,
  `accepted_transport_hotspot_location = outer`,
  `accepted_outer_boundary_dominant_family = surface_pressure`
- `selected_pressure_target-default-12`: `converged = false`,
  `accepted_step_count = 8`, `rejected_trial_count = 933`,
  `initial_merit = 7.542577331627505`, `final_merit = 4.407889109608119`,
  `accepted_transport_hotspot_location = outer`,
  `accepted_outer_boundary_dominant_family = surface_pressure`

The focused perturbation cases keep the same high-level pattern:

- both lanes remain `converged = false`,
- both lanes keep `used_regularized_fallback = true`,
- the accepted transport hotspot stays `outer`,
- and the accepted outer-boundary dominant family stays `surface_pressure`.

## Interpretation

This is not a null result, but it is not a promotion result either.

Aligning the outer transport pressure target to the selected surface-pressure
target lowers the `default-12` merit materially, which means the pressure-side
coupling mismatch is numerically live. But the same control lane still fails to
converge, still keeps the transport hotspot on the outer row, still leaves the
accepted outer-boundary dominant family at `surface_pressure`, and still uses
the regularized fallback path.

That means the mismatch matters, but the remaining near-term owner is deeper
than target alignment alone. The pressure-side coupling story is not finished
at the level of a single target swap.

## what this does not prove

- This does not prove that `selected_pressure_target` should become the live
  outer transport default.
- This does not prove that the remaining issue is fully explained by pressure
  target mismatch.
- This does not prove that the bridge pressure closure is physically final.
- This does not prove convergence across the focused bundle or broader model
  families.

## Next step

Keep the outer-transport alignment lane internal and diagnostic-only. The
measured result says the mismatch is numerically real, but it is not by itself
the convergence fix. The next high-impact slice should therefore move one layer
deeper into outer transport / pressure-side coupling rather than widening the
control matrix indefinitely.
