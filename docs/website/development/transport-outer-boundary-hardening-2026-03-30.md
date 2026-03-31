# Transport Outer Boundary Hardening, 2026-03-30

This note records the current transport-family hardening evidence after the transport sign contract correction. The refreshed artifact bundle now lives at `artifacts/validation/2026-03-30-transport-sign-correction/`.

## What was measured

The bundle covers the default-12 fixture, the `n_cells = 6, 8, 12, 16, 24` ladder, and three deterministic perturbation cases. The key measured facts are:

- `default-12`: `converged = false`, `accepted_step_count = 6`, `rejected_trial_count = 735`, `final_weighted_residual_norm = 0.26449516386740546`, `final_merit = 1.7489422927311415`, `accepted_dominant_family = surface`, `accepted_transport_hotspot.location = outer`, `accepted_transport_hotspot.cell_index = 11`, `accepted_transport_hotspot.weighted_contribution = 0.8444699228014957`, `best_rejected_transport_hotspot.location = outer`, `best_rejected_transport_hotspot.cell_index = 11`, `used_regularized_fallback = true`
- `cells-6`: `accepted_dominant_family = hydrostatic`, but the accepted transport hotspot is `interior` at cell index `4`
- `cells-8`: `accepted_dominant_family = hydrostatic`, while the accepted transport hotspot stays `outer` at cell index `7`
- `cells-12`: matches `default-12`, with the accepted transport hotspot on the outer row at cell index `11`
- `cells-16`: `accepted_dominant_family = outer_transport`, and the accepted transport hotspot is `outer` at cell index `15`
- `cells-24`: `accepted_dominant_family = interior_transport`, but the accepted transport hotspot is still `outer` at cell index `23`
- `perturb-a1e-6-case-01`, `perturb-a1e-6-case-02`, and `perturb-a1e-6-case-03`: `accepted_dominant_family = surface`, and the accepted transport hotspot is `outer` at cell index `11`

The transport hotspot language matters here. It names the single transport row with the largest weighted contribution and records both its location and cell index. That is diagnostic-only evidence; it does not redefine any residual row family.

## Interpretation

The transport sign contract correction changes the measured interpretation materially. In the earlier hotspot bundle, the default-12 accepted transport hotspot was the surface-adjacent interior row at cell index `10`. In the refreshed sign-corrected bundle, the default-12 accepted transport hotspot moves to the outer row at cell index `11`, and the accepted dominant family moves from `interior_transport` to `surface`.

That means the earlier surface-adjacent interior diagnosis was not stable under a physically consistent transport sign contract. The corrected contract does not make the solve healthy, but it does say that further hardening should not assume the previous interior transport hotspot attribution was conditioning-only truth. The refreshed bundle points much more strongly at the outer row and the surface-coupled rows than the stale-sign bundle did.

What changed numerically is mixed but informative. Most fixtures improve in weighted norm and merit after the sign correction: `default-12` drops from `0.2964799113980498` to `0.26449516386740546` in weighted residual norm, `cells-6` drops from `0.4811575368190196` to `0.3068567125800897`, and `cells-16` drops from `0.2559834127785592` to `0.20845832512923232`. But `perturb-a1e-6-case-03` gets worse, with weighted residual norm rising from `0.30221106648454077` to `0.35820341807785544` and merit rising from `2.2832882176430886` to `3.2077422180664725`. So this is a transport sign contract correction, not a general convergence improvement claim.

Boundary rows own the edge equations of the global residual, but they do not own EOS, opacity, or atmosphere microphysics internals. That boundary ownership split keeps the contract narrow and makes it easier to say where the row-family evidence actually points.

## Boundary validity checks

The boundary contract is acceptable only when:

- the center targets remain well scaled as the inner mass cell shrinks,
- the outer closure returns thermodynamically admissible surface values,
- the boundary rows do not dominate the residual only because of unit or scale mismatch,
- and converged solutions are not hypersensitive to the exact outer attachment choice.

The present bundle satisfies none of the convergence claims yet, but it does provide a cleaner diagnosis target for the next slice: transport-family conditioning with explicit transport hotspot location and cell index evidence.

## What this does not prove

The hotspot evidence does not yet isolate the scientific owner of the near-surface failure. An outer-row hotspot after the transport sign contract correction could still come from:

- transport-row physics in the current radiative-gradient stencil,
- surface attachment semantics feeding the near-surface pressure span,
- surface-row scaling and merit attribution around the outer match point,
- or local nonlinearity in the one-sided outer transport stencil.

So this note records a refreshed transport hotspot diagnosis, not a proof that the outer boundary or the radiative law alone is wrong. Every payload is still `converged = false`, and `used_regularized_fallback = true` remains true everywhere in the refreshed bundle.

## Next step

Keep the transport sign contract explicit in the docs, and use the refreshed bundle to harden the outer transport and surface-coupled rows before making any broader conditioning or ownership claims.
