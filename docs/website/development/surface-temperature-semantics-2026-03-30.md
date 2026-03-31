# Surface Temperature Semantics, 2026-03-30

This note records the live post-fix surface-temperature semantics interpretation for the focused `2026-03-30-surface-temperature-semantics-audit` bundle at `artifacts/validation/2026-03-30-surface-temperature-semantics-audit/`.

## Code-backed current state

The live outer-boundary temperature stack is now:

- `outer_match_temperature_k(problem, model)` uses the corrected Eddington-grey photosphere at `tau = 2/3` plus the local half-cell transport bridge,
- `surface_temperature_semantics(problem, model)` decomposes the live surface-temperature row into the cell temperature, the photospheric reference, the match point, and the derived log gaps,
- the surface-temperature residual row is still `log(T_surface / T_match)`,
- and the audit remains diagnostic-only: it rebuilds the live four-case bundle without changing any solver-owned equations.

That means this note is about the live semantics of the current surface-temperature row, not about the earlier pre-cutover ownership mismatch.

## Measured bundle

Every payload in the focused bundle is still `converged = false` and `used_regularized_fallback = true`.

| case | accepted `surface_to_photosphere_log_gap` | accepted `match_to_photosphere_log_gap` | accepted `surface_to_match_log_gap` | accepted `transport_temperature_offset_fraction` |
| --- | ---: | ---: | ---: | ---: |
| `default-12` | `4.835945487188869` | `10.092036242100313` | `-5.256090754911444` | `24148.917480064203` |
| `perturb-a1e-6-case-01` | `6.202319106640088` | `13.263004639086038` | `-7.06068553244595` | `575504.8309621394` |
| `perturb-a1e-6-case-02` | `1.0000080943908394` | `8.158074463081523` | `-7.158066368690683` | `3490.4571972496237` |
| `perturb-a1e-6-case-03` | `6.6588153112873485` | `13.193880865733526` | `-6.535065554446177` | `537067.4676986933` |

The sign identity holds in the live bundle:

- `surface_to_match_log_gap = surface_to_photosphere_log_gap - match_to_photosphere_log_gap`

The important structural pattern is also consistent across all four cases:

- `match_to_photosphere_log_gap` is larger than `surface_to_photosphere_log_gap` in every focused payload,
- `surface_to_match_log_gap` stays large and negative in every focused payload,
- and `transport_temperature_offset_fraction` remains far above unity in every focused payload.

## Interpretation

The live surface-temperature row is bridge-dominated across the focused post-fix bundle.

That is the point of this slice. The current row is not primarily failing because the outer cell sits a little above or below the Eddington photosphere. It is failing because the bridged match point sits far above the photospheric reference, and the cell never catches up to that bridged target.

`Insight ----------------------------------------`
- This is a semantics diagnosis, not yet a model correction.
- The live failure is now clearly about the size of the temperature bridge relative to the photospheric anchor.
- That makes the next slice sharper: test the bridge semantics directly before introducing a richer atmosphere model.
`------------------------------------------------`

This does not mean the outer transport row is irrelevant. It remains the largest transport hotspot in the focused bundle. But the temperature semantics audit now says the sharpest surviving owner is the temperature bridge itself, not a near-photosphere cell mismatch and not a mixed pressure-versus-temperature story.

## what this does not prove

- This does not prove robust convergence.
- This does not prove that Hopf is required.
- This does not prove that the current bridge semantics are correct.
- This does not prove that the outer transport row can be ignored.
