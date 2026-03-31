# Surface Owner Localization, 2026-03-30

This note records the live post-temperature-fix interpretation of the focused `2026-03-30-surface-owner-localization-audit` bundle at `artifacts/validation/2026-03-30-surface-owner-localization-audit/`.

Retention status: `historical`

## Code-backed current state

The live outer-boundary helper stack is now:

- `outer_match_temperature_k(problem, model)` uses the Eddington-grey photosphere at `tau = 2/3` plus the local half-cell transport bridge,
- `outer_match_pressure_dyn_cm2(problem, model)` still uses the shared `P_ph + g σ_half` bridge,
- the outer transport row remains one-sided to the photospheric face,
- and the focused audit is diagnostic-only: it rebuilds the live solver state without changing any solver-owned equations.

That matters because the earlier fitting-point note is now historical evidence about the pre-cutover temperature mismatch, not the current live-state interpretation.

## Measured bundle

Every payload in the focused bundle is still `converged = false` and `used_regularized_fallback = true`.

| case | accepted dominant family | accepted dominant surface family | accepted `outer_transport_weighted` | accepted `surface_temperature_weighted` | accepted `surface_pressure_weighted` | accepted transport hotspot |
| --- | --- | --- | ---: | ---: | ---: | --- |
| `default-12` | `surface` | `surface_temperature` | `0.8613650776647748` | `-5.256090754911444` | `-1.6346969697921523` | `outer`, cell `11` |
| `perturb-a1e-6-case-01` | `surface` | `surface_temperature` | `0.9937018144021625` | `-7.06068553244595` | `-3.4351684261253865` | `outer`, cell `11` |
| `perturb-a1e-6-case-02` | `surface` | `surface_temperature` | `0.9050492336409105` | `-7.158066368690683` | `-3.5364541266353093` | `outer`, cell `11` |
| `perturb-a1e-6-case-03` | `surface` | `surface_temperature` | `0.9547326476795024` | `-6.535065554446177` | `-2.9137945991812586` | `outer`, cell `11` |

The bundle is no longer mixed in this focused four-case view. All four focused cases accept on `surface_temperature`, and the outer transport hotspot stays on the outer row at cell index `11`.

The default-12 payload is representative of the live post-fix state:

- `accepted_step_count = 8`
- `rejected_trial_count = 680`
- `final_weighted_residual_norm = 0.812065048601674`
- `final_merit = 16.48624107901098`
- `accepted_dominant_surface_family = surface_temperature`

## Interpretation

The current live post-fix stop-rule outcome is sharper than the earlier mixed ownership story:

- the old temperature helper mismatch is gone,
- the focused bundle is now unanimously `surface_temperature` across `default-12` plus the three deterministic perturbations,
- and the outer transport row remains the largest transport hotspot, but it is secondary to the surface-temperature row in weighted magnitude in every focused payload.

This is still not a convergence claim. It is a localization claim. Under the corrected Eddington-grey temperature owner, the remaining near-surface failure in the focused bundle is now best described as a temperature-dominated surface failure with a persistent outer-row transport secondary signal.

`Insight ----------------------------------------`
- This note is about the live code path, not the historical pre-cutover audit.
- The important structural shift is that the focused bundle is no longer split between `surface_pressure` and `surface_temperature`.
- That means the next slice should treat surface-temperature semantics as the sharp owner to interrogate, while keeping the outer transport row visible as a secondary coupling target.
`------------------------------------------------`

## what this does not prove

- This does not prove robust convergence.
- This does not prove that Hopf is needed.
- This does not prove that the outer transport row is irrelevant.
- This does not prove parity with any external atmosphere implementation.
