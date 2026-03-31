# Surface Temperature Semantics, 2026-03-30

This note records the live post-cutover surface-temperature semantics for the focused `2026-03-30-surface-temperature-semantics-audit` bundle at `artifacts/validation/2026-03-30-surface-temperature-semantics-audit/`.

## Code-backed current state

The live outer-boundary temperature stack is now split deliberately:

- `outer_match_temperature_k(problem, model)` returns the photospheric-face temperature target directly at ASTRA's Eddington photosphere,
- `surface_temperature_semantics(problem, model)` still decomposes the live surface-temperature row into the cell temperature, the photospheric reference, the match point, and the derived log gaps,
- the pressure and optical-depth helpers still reference the deeper one-sided matching layer,
- and the audit remains diagnostic-only: it rebuilds the live four-case bundle without changing any solver-owned equations.

That means this note is about the live semantics of the current surface-temperature row, not about the earlier pre-cutover ownership mismatch.

## Measured bundle

Every payload in the focused bundle is still `converged = false` and `used_regularized_fallback = true`.

| case | accepted dominant surface family | accepted `surface_to_photosphere_log_gap` | accepted `match_to_photosphere_log_gap` | accepted `surface_to_match_log_gap` | accepted `transport_temperature_offset_fraction` |
| --- | --- | ---: | ---: | ---: | ---: |
| `default-12` | `surface_pressure` | `0.06615610172518238` | `0.0` | `0.06615610172518238` | `1198.0024782432183` |
| `perturb-a1e-6-case-01` | `surface_pressure` | `0.12500917600285` | `0.0` | `0.12500917600285` | `1454.1932286815659` |
| `perturb-a1e-6-case-02` | `surface_pressure` | `8.093711789669555e-6` | `0.0` | `8.093711789669555e-6` | `1283.4091164759857` |
| `perturb-a1e-6-case-03` | `surface_pressure` | `0.09223041340830207` | `0.0` | `0.09223041340830207` | `1407.719965864372` |

The sign identity holds in the live bundle:

- `surface_to_match_log_gap = surface_to_photosphere_log_gap - match_to_photosphere_log_gap`

The important structural pattern is also consistent across all four cases:

- `match_to_photosphere_log_gap = 0.0` in every focused payload,
- `surface_to_match_log_gap` now tracks the small photospheric offset rather than a large transport bridge,
- and `transport_temperature_offset_fraction` remains far above unity in every focused payload.

## Interpretation

The live surface-temperature row is now photosphere-anchored across the focused post-cutover bundle.

That is the point of this slice. The current row is no longer failing because the outer cell is trying to chase a bridged match point far above the photospheric reference. Instead, the residual surface ownership now lands on `surface_pressure` in every focused case, while the temperature helper itself is tied to the photospheric face.

`Insight ----------------------------------------`
- This is still a semantics diagnosis, not a model-completeness claim.
- The live temperature owner is now the photosphere itself, while the pressure and optical-depth helpers remain in the deeper matching layer.
- That makes the next slice sharper: inspect the surviving `surface_pressure` semantics before widening scope to richer atmosphere models.
`------------------------------------------------`

This does not mean the outer transport row is irrelevant. It remains the largest transport hotspot in the focused bundle. But the temperature semantics audit now says the sharpest surviving owner is the pressure-side surface row, not a temperature bridge.

what this does not prove is that the deeper match-point helpers are already correct.

## What this does not prove

- This does not prove robust convergence.
- This does not prove that Hopf is required.
- This does not prove that the deeper match-point helpers are already correct.
- This does not prove that the outer transport row can be ignored.
