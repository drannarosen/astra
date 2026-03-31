# Transport Outer Boundary Hardening, 2026-03-30

This note records the current transport-family hardening evidence after the transport sign contract correction. The refreshed artifact bundle now lives at `artifacts/validation/2026-03-30-transport-sign-correction/`.

## Outer Surface Coupling Audit

The follow-up audit bundle now lives at `artifacts/validation/2026-03-30-outer-surface-coupling-audit/`. Its purpose is narrower than the earlier transport-family note: it asks which near-surface owner is actually sharpest once the surface row is split into row-level families and the outer boundary summary is recorded explicitly.

## What was measured

The bundle covers the default-12 fixture, the `n_cells = 6, 8, 12, 16, 24` ladder, and three deterministic perturbation cases. The key measured facts are:

- `default-12`: `converged = false`, `accepted_step_count = 6`, `rejected_trial_count = 735`, `final_weighted_residual_norm = 0.26449516386740546`, `final_merit = 1.7489422927311415`, `accepted_dominant_family = surface`, `accepted_dominant_surface_family = surface_pressure`, `accepted_outer_boundary.outer_transport_weighted = 0.8444699228014957`, `accepted_outer_boundary.surface_temperature_weighted = 0.6854069474453723`, `accepted_outer_boundary.surface_pressure_weighted = -0.7960701554689767`, `accepted_outer_boundary.match_temperature_k = 1.1733423492649216e6`, `accepted_outer_boundary.match_pressure_dyn_cm2 = 3.9370078676338625e13`, `accepted_transport_hotspot.location = outer`, `accepted_transport_hotspot.cell_index = 11`
- `best-rejected default-12`: `best_rejected_dominant_family = surface`, `best_rejected_dominant_surface_family = surface_pressure`, `best_rejected_outer_boundary.outer_transport_weighted = 0.9023026625735826`, `best_rejected_outer_boundary.surface_temperature_weighted = 0.6845184249650771`, `best_rejected_outer_boundary.surface_pressure_weighted = -0.7946999023083491`, `best_rejected_outer_boundary.match_temperature_k = 1.1744034147186459e6`, `best_rejected_outer_boundary.match_pressure_dyn_cm2 = 3.936737935411116e13`, `best_rejected_transport_hotspot.location = outer`, `best_rejected_transport_hotspot.cell_index = 11`

- `default-12`: `converged = false`, `accepted_step_count = 6`, `rejected_trial_count = 735`, `final_weighted_residual_norm = 0.26449516386740546`, `final_merit = 1.7489422927311415`, `accepted_dominant_family = surface`, `accepted_transport_hotspot.location = outer`, `accepted_transport_hotspot.cell_index = 11`, `accepted_transport_hotspot.weighted_contribution = 0.8444699228014957`, `best_rejected_transport_hotspot.location = outer`, `best_rejected_transport_hotspot.cell_index = 11`, `used_regularized_fallback = true`
- `cells-6`: `accepted_dominant_family = hydrostatic`, but the accepted transport hotspot is `interior` at cell index `4`
- `cells-8`: `accepted_dominant_family = hydrostatic`, while the accepted transport hotspot stays `outer` at cell index `7`
- `cells-12`: matches `default-12`, with the accepted transport hotspot on the outer row at cell index `11`
- `cells-16`: `accepted_dominant_family = outer_transport`, and the accepted transport hotspot is `outer` at cell index `15`
- `cells-24`: `accepted_dominant_family = interior_transport`, but the accepted transport hotspot is still `outer` at cell index `23`
- `perturb-a1e-6-case-01`, `perturb-a1e-6-case-02`, and `perturb-a1e-6-case-03`: `accepted_dominant_family = surface`, and the accepted transport hotspot is `outer` at cell index `11`

The transport hotspot language matters here. It names the single transport row with the largest weighted contribution and records both its location and cell index. That is diagnostic-only evidence; it does not redefine any residual row family.

## Interpretation

The transport sign contract correction changes the measured interpretation materially, but the new outer surface coupling audit says the remaining near-surface owner is not plain outer transport. The earlier transport hotspot bundle had pointed at a surface-adjacent interior transport row in the `interior_transport` family, but the refreshed bundle now says the accepted dominant surface family is `surface_pressure`, and the best rejected dominant surface family is also `surface_pressure`, with `accepted_outer_boundary.surface_pressure_weighted = -0.7960701554689767` and `best_rejected_outer_boundary.surface_pressure_weighted = -0.7946999023083491`. The outer transport row is still the largest transport hotspot at cell index `11`, but the surface-pressure row is the sharpest surface-family owner on this bundle.

That is a structural answer, not a convergence claim. The corrected contract does not make the solve healthy, and the bundle does not support a single-owner hardening story across every case. The perturbation fixtures split between `surface_pressure` and `surface_temperature`, while `cells-16` and `cells-24` keep the transport hotspot outer and the dominant surface family fixed at `surface_pressure`. So the bundle is sharper than the old `surface` versus `outer_transport` split, but still mixed enough that the next owner is best described as a surface-pressure-dominated near-surface failure with temperature-coupled outliers.

What changed numerically is mixed but informative. Most fixtures improve in weighted norm and merit after the sign correction: `default-12` stays at `0.26449516386740546` in weighted residual norm, `cells-6` is `0.3068567125800897`, and `cells-16` is `0.20845832512923232`. But `perturb-a1e-6-case-02` and `perturb-a1e-6-case-03` remain worse than the default case, with dominant surface family `surface_temperature`. So this is still a transport sign contract correction plus a near-surface ownership audit, not a general convergence improvement claim.

Boundary rows own the edge equations of the global residual, but they do not own EOS, opacity, or atmosphere microphysics internals. That boundary ownership split keeps the contract narrow and makes it easier to say where the row-family evidence actually points.

## Boundary validity checks

The boundary contract is acceptable only when:

- the center targets remain well scaled as the inner mass cell shrinks,
- the outer closure returns thermodynamically admissible surface values,
- the boundary rows do not dominate the residual only because of unit or scale mismatch,
- and converged solutions are not hypersensitive to the exact outer attachment choice.

The present bundle satisfies none of the convergence claims yet, but it does provide a cleaner diagnosis target for the next slice: surface-pressure semantics and scaling first, with the outer transport row still a visible secondary target because the transport hotspot remains on the outer row at cell index `11`.

## What this does not prove

The hotspot evidence does not yet isolate the scientific owner of the near-surface failure. An outer-row hotspot after the transport sign contract correction and the outer surface coupling audit could still come from:

- transport-row physics in the current radiative-gradient stencil,
- surface attachment semantics feeding the near-surface pressure span,
- surface-row scaling and merit attribution around the outer match point,
- or local nonlinearity in the one-sided outer transport stencil.

So this note records a refreshed transport hotspot diagnosis and a row-level outer surface coupling audit, not a proof that the outer boundary or the radiative law alone is wrong. Every payload is still `converged = false`, and `used_regularized_fallback = true` remains true everywhere in the refreshed bundle.

## Next step

Keep the transport sign contract explicit in the docs, and use the refreshed bundle to harden the surface_pressure semantics first, while leaving the transport hotspot on the outer row as the secondary diagnostic target.
