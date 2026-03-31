# Surface Pressure Log Contract, 2026-03-30

This note records the surface-pressure contract update after the `2026-03-30-surface-pressure-log-contract` audit bundle was regenerated at `artifacts/validation/2026-03-30-surface-pressure-log-contract/`.

## What was measured

The bundle covers the default-12 fixture, the `n_cells = 6, 8, 12, 16, 24` ladder, and three deterministic perturbation cases. The key measured facts are:

- `default-12`: `converged = false`, `accepted_step_count = 7`, `rejected_trial_count = 1232`, `final_weighted_residual_norm = 0.24783903118721756`, `final_merit = 1.5356046344954652`, `accepted_dominant_family = outer_transport`, `accepted_dominant_surface_family = surface_pressure`, `accepted_outer_boundary.surface_pressure_ratio = 2.3390261279875415`, `accepted_outer_boundary.surface_pressure_log_mismatch = 0.8497346581200489`, `accepted_outer_boundary.outer_transport_weighted = 0.9647073026988532`, `accepted_outer_boundary.surface_temperature_weighted = -0.1720352976052002`, `accepted_transport_hotspot.location = outer`, `accepted_transport_hotspot.cell_index = 11`
- `best-rejected default-12`: `best_rejected_dominant_family = outer_transport`, `best_rejected_dominant_surface_family = surface_pressure`, `best_rejected_outer_boundary.surface_pressure_ratio = 2.3364618170676366`, `best_rejected_outer_boundary.surface_pressure_log_mismatch = 0.8486377410892878`, `best_rejected_outer_boundary.outer_transport_weighted = 0.9029845345363843`, `best_rejected_outer_boundary.surface_temperature_weighted = -0.1718132197845499`, `best_rejected_transport_hotspot.location = outer`, `best_rejected_transport_hotspot.cell_index = 11`
- `cells-6`: `accepted_dominant_family = interior_transport`, but the accepted dominant surface family is `surface_pressure`
- `cells-8`: `accepted_dominant_family = surface`, and the accepted dominant surface family is `surface_pressure`
- `cells-12`: matches `default-12`, with the accepted dominant family now `outer_transport`
- `cells-16`: `accepted_dominant_family = surface`, and the accepted dominant surface family is `surface_pressure`
- `cells-24`: `accepted_dominant_family = surface`, and the accepted dominant surface family is `surface_pressure`
- `perturb-a1e-6-case-01`: `accepted_dominant_family = surface`, and the accepted dominant surface family is `surface_temperature`
- `perturb-a1e-6-case-02`: `accepted_dominant_family = surface`, and the accepted dominant surface family is `surface_pressure`
- `perturb-a1e-6-case-03`: `accepted_dominant_family = surface`, and the accepted dominant surface family is `surface_temperature`

## Interpretation

This bundle shows real progress, but it is still mixed.

The default-12 fixture improved relative to the earlier outer-surface audit: the weighted residual norm fell from `0.26449516386740546` to `0.24783903118721756`, the merit fell from `1.7489422927311415` to `1.5356046344954652`, and the accepted step count rose from `6` to `7`. At the same time, the rejected-trial count worsened from `735` to `1232`, so this is not a clean convergence win.

The important structural change is that the top-level accepted dominant family moved to `outer_transport`, while the sharpest surface-family owner stayed `surface_pressure`. The accepted and best-rejected default-12 pressure ratios are both about `2.34`, and the pressure log mismatch is about `0.85` in both cases. That tells us the pressure row meaning is now explicit and measurable, but the bundle still points to shared pressure-match semantics or pressure-row scaling as the next narrow owner.

What changed numerically is mixed across the rest of the bundle. The perturbation cases still split between `surface_pressure` and `surface_temperature`, so the audit is sharper than before but not singular. That is real progress in diagnosis, not a claim that the solver is close to physically trustworthy convergence.

## what this does not prove

The bundle does not prove that the log-pressure contract alone fixes the classical solver.

It does not prove that the outer transport row is no longer important, because `accepted_dominant_family = outer_transport` for `default-12`.

It does not prove that surface-pressure semantics are the only remaining problem, because some perturbations still flip to `surface_temperature`.

Every payload is still `converged = false`, and `used_regularized_fallback = true` remains present everywhere.

## Next step

Keep the new log-pressure surface contract explicit, treat `surface_pressure` as the sharpest current surface-family owner on `default-12`, and move to the next narrow pressure-match/attachment semantics audit instead of a broad solver rewrite.
