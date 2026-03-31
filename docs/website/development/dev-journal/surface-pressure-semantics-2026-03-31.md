# Surface Pressure Semantics, 2026-03-31

This note records the live post-cutover surface-pressure semantics for the focused `2026-03-31-surface-pressure-semantics-audit` bundle at `artifacts/validation/2026-03-31-surface-pressure-semantics-audit/`.

Retention status: `current`

## Code-backed current state

- `outer_match_temperature_k(problem, model)` remains photospheric at the Eddington face.
- `outer_match_pressure_dyn_cm2(problem, model)` still uses the deeper one-sided `P_ph + g σ_half` match point.
- `surface_pressure_semantics(problem, model)` decomposes the live pressure row into the surface pressure, the photospheric pressure anchor, the deeper match point, and the derived log gaps.
- the audit remains diagnostic-only: it rebuilds the live four-case bundle without changing any solver-owned equations.

## Measured bundle

Every payload in the focused bundle is still `converged = false` and `used_regularized_fallback = true`.

| case | accepted dominant surface family | accepted `pressure_surface_to_photosphere_log_gap` | accepted `pressure_match_to_photosphere_log_gap` | accepted `pressure_surface_to_match_log_gap` | accepted `hydrostatic_pressure_offset_fraction` |
| --- | --- | ---: | ---: | ---: | ---: |
| `default-12` | `surface_pressure` | `46.97031727130823` | `50.25470107421815` | `-3.2843838029099146` | `6.688663787248943e21` |
| `perturb-a1e-6-case-01` | `surface_pressure` | `43.307259814891026` | `46.732451454608366` | `-3.4251916397173403` | `1.975357895263058e20` |
| `perturb-a1e-6-case-02` | `surface_pressure` | `43.21386663947494` | `46.685764359901654` | `-3.4718977204267176` | `1.885253887238918e20` |
| `perturb-a1e-6-case-03` | `surface_pressure` | `42.53371150055234` | `46.06555604805966` | `-3.531844547507319` | `1.0139506021751634e20` |

The log-gap identity holds in the live bundle:

- `pressure_surface_to_match_log_gap = pressure_surface_to_photosphere_log_gap - pressure_match_to_photosphere_log_gap`

The important structural pattern is also consistent across all four cases:

- `pressure_match_to_photosphere_log_gap` is large and positive in every focused payload,
- `pressure_surface_to_photosphere_log_gap` is also large and positive in every focused payload,
- `pressure_surface_to_match_log_gap` stays negative in every focused payload,
- and `hydrostatic_pressure_offset_fraction` remains enormous in every focused payload.

## Interpretation

The live surface-pressure row is bridge-dominated across the focused post-cutover bundle.

That is the point of this slice. The pressure row is not primarily comparing the surface cell against a small photospheric pressure anchor. In the live bundle, the deeper hydrostatic bridge sets the pressure scale almost entirely, and the residual records that the surface cell still sits several dex below that deeper match point.

`Insight ----------------------------------------`
- The photospheric pressure anchor is still present in the code, but it is not the practical owner of the live pressure mismatch in this bundle.
- The deeper `P_ph + g σ_half` bridge dominates the scale of both the match point and the surviving residual.
- That means the next boundary discussion should be about the pressure bridge semantics, not about returning to the temperature row.
`------------------------------------------------`

This does not mean the outer transport row is irrelevant. The accepted transport hotspot still sits on the outer row at cell index `11` in every focused payload. But the pressure semantics audit now says the sharpest surviving surface owner is the deeper pressure bridge, not the photospheric pressure anchor.

## what this does not prove

- This does not prove robust convergence.
- This does not prove that Hopf is required.
- This does not prove that the current pressure bridge semantics are correct.
- This does not prove that the outer transport row can be ignored.
