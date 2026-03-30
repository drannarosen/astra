# Transport Outer Boundary Hardening, 2026-03-30

This note records the current validation slice for the transport-family hardening work. The relevant artifact bundle lives at `artifacts/validation/2026-03-30-transport-outer-boundary-hardening/`.

## What was measured

The bundle covers the default-12 fixture, the `n_cells = 6, 8, 12, 16, 24` ladder, and three deterministic perturbation cases. The key measured facts are:

- `default-12`: `converged = false`, `accepted_step_count = 6`, `rejected_trial_count = 735`, `final_residual_norm = 4.445034828051614e22`, `final_weighted_residual_norm = 0.2964799113980498`, `final_merit = 2.1975084465648864`, `accepted_dominant_family = interior_transport`, `best_rejected_dominant_family = interior_transport`, `used_regularized_fallback = true`
- `cells-6`: `converged = false`, `accepted_step_count = 8`, `rejected_trial_count = 1179`, `final_weighted_residual_norm = 0.4811575368190196`, `final_merit = 3.009663478090701`, `accepted_dominant_family = outer_transport`, `best_rejected_dominant_family = outer_transport`, `used_regularized_fallback = true`
- `cells-8`: `converged = false`, `accepted_step_count = 8`, `rejected_trial_count = 545`, `final_weighted_residual_norm = 0.3776685847493437`, `final_merit = 2.4247705184117283`, `accepted_dominant_family = outer_transport`, `best_rejected_dominant_family = outer_transport`, `used_regularized_fallback = true`
- `cells-12`, `cells-16`, `cells-24`, and `perturb-a1e-6-case-03`: `accepted_dominant_family = interior_transport`
- `perturb-a1e-6-case-01` and `perturb-a1e-6-case-02`: `accepted_dominant_family = surface`

## Interpretation

The new split diagnostics do not support a purely outer-boundary-local diagnosis. The smallest cell ladders still lean outer transport, but the default-12 case and the larger-cell ladder are interior transport-dominant. In code terms, that is `outer_transport` in the smallest ladders and `interior_transport` in the default and larger ladders. The safest scientific reading is therefore mixed transport-family trouble with boundary sensitivity, not a boundary-only failure.

Boundary rows own the edge equations of the global residual, but they do not own EOS, opacity, or atmosphere microphysics internals. That boundary ownership split keeps the contract narrow and makes it easier to say where the row-family evidence actually points.

## Boundary validity checks

The boundary contract is acceptable only when:

- the center targets remain well scaled as the inner mass cell shrinks,
- the outer closure returns thermodynamically admissible surface values,
- the boundary rows do not dominate the residual only because of unit or scale mismatch,
- and converged solutions are not hypersensitive to the exact outer attachment choice.

The present bundle satisfies none of the convergence claims yet, but it does provide a cleaner diagnosis target for the next slice: transport-family conditioning with explicit interior-versus-outer evidence.

## Next step

Keep the boundary contract explicit in the docs, and harden the mixed transport-family rows before claiming that the outer boundary is the sole bottleneck.
