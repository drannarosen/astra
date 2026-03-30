# Transport Outer Boundary Hardening, 2026-03-30

This note records the current transport-family hardening evidence after the refreshed transport hotspot bundle. The relevant artifact bundle now lives at `artifacts/validation/2026-03-30-transport-hotspot-diagnostics/`.

## What was measured

The bundle covers the default-12 fixture, the `n_cells = 6, 8, 12, 16, 24` ladder, and three deterministic perturbation cases. The key measured facts are:

- `default-12`: `converged = false`, `accepted_step_count = 6`, `rejected_trial_count = 735`, `final_weighted_residual_norm = 0.2964799113980498`, `final_merit = 2.1975084465648864`, `accepted_dominant_family = interior_transport`, `accepted_transport_hotspot.location = interior`, `accepted_transport_hotspot.cell_index = 10`, `accepted_transport_hotspot.weighted_contribution = -1.0085188425976508`, `best_rejected_transport_hotspot.location = interior`, `best_rejected_transport_hotspot.cell_index = 10`, `used_regularized_fallback = true`
- `cells-6`: `accepted_dominant_family = outer_transport`, `accepted_transport_hotspot.location = outer`, `accepted_transport_hotspot.cell_index = 5`, `best_rejected_transport_hotspot.location = outer`, `best_rejected_transport_hotspot.cell_index = 5`
- `cells-8`: `accepted_dominant_family = outer_transport`, `accepted_transport_hotspot.location = outer`, `accepted_transport_hotspot.cell_index = 7`, `best_rejected_transport_hotspot.location = outer`, `best_rejected_transport_hotspot.cell_index = 7`
- `cells-12`, `cells-16`, and `cells-24`: `accepted_transport_hotspot.location = interior` at cell index `10`, `14`, and `21`
- `perturb-a1e-6-case-01` and `perturb-a1e-6-case-02`: `accepted_dominant_family = surface`, but the transport hotspot is still `interior` at cell index `10`
- `perturb-a1e-6-case-03`: `accepted_dominant_family = interior_transport`, but the accepted transport hotspot flips to `outer` at cell index `11` while the best rejected transport hotspot stays `interior` at cell index `10`

The transport hotspot language matters here. It names the single transport row with the largest weighted contribution and records both its location and cell index. That is diagnostic-only evidence; it does not redefine any residual row family.

## Interpretation

The refreshed hotspot diagnostics point away from a purely outer-boundary-local diagnosis. The smallest cell ladders still peak on the one-sided outer transport row, but the default-12 case and the larger-cell ladder now peak on a surface-adjacent interior transport row instead. In the default-12 payload, that hotspot is the interior row at cell index `10`, not the outer row at cell index `11`.

That is a more specific scientific statement than the earlier family split. The current evidence still says transport-family trouble with boundary sensitivity, but the sharpest repeated hotspot is now surface-adjacent interior transport rather than the one-sided outer boundary row alone.

Boundary rows own the edge equations of the global residual, but they do not own EOS, opacity, or atmosphere microphysics internals. That boundary ownership split keeps the contract narrow and makes it easier to say where the row-family evidence actually points.

## Boundary validity checks

The boundary contract is acceptable only when:

- the center targets remain well scaled as the inner mass cell shrinks,
- the outer closure returns thermodynamically admissible surface values,
- the boundary rows do not dominate the residual only because of unit or scale mismatch,
- and converged solutions are not hypersensitive to the exact outer attachment choice.

The present bundle satisfies none of the convergence claims yet, but it does provide a cleaner diagnosis target for the next slice: transport-family conditioning with explicit transport hotspot location and cell index evidence.

## What this does not prove

The hotspot evidence does not yet isolate the scientific owner of the near-surface failure. A surface-adjacent interior hotspot could still come from:

- transport-row physics in the current radiative-gradient stencil,
- surface attachment semantics feeding the near-surface pressure span,
- or local nonlinearity in the surface-adjacent transport stencil.

So this note records a transport hotspot diagnosis, not a proof that the outer boundary or the radiative law alone is wrong.

## Next step

Keep the boundary contract explicit in the docs, and harden the surface-adjacent transport rows before claiming that the one-sided outer boundary row is the sole bottleneck.
