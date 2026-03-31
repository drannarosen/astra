# Progress Summary

This page is ASTRA's dated executive journal. Each entry should be short enough to scan quickly, but concrete enough to tell a new contributor what really changed.

## Entry template

For each update, record:

- the date,
- the slice that landed,
- the main architectural or scientific consequence,
- the verification that was run,
- and the next intended step.

## 2026-03-30

### Surface temperature photospheric cutover

ASTRA's refreshed `2026-03-30-surface-temperature-semantics-audit` bundle now says the live temperature owner is photospheric, not bridge-dominated. In all four focused payloads the accepted dominant surface family is `surface_pressure`, `match_to_photosphere_log_gap = 0.0`, and the live temperature row sits on the Eddington photosphere while the pressure and optical-depth helpers still reference the deeper matching concept.

Measured post-cutover facts:

- `default-12` has `accepted_dominant_surface_family = surface_pressure`,
- `default-12` has `surface_to_photosphere_log_gap = 0.06615610172518238`,
- `default-12` has `surface_to_match_log_gap = 0.06615610172518238`,
- `default-12` keeps `accepted_transport_hotspot.location = outer` at cell index `11`,
- all four focused cases have `accepted_dominant_surface_family = surface_pressure`,
- all four focused cases have `match_to_photosphere_log_gap = 0.0`,
- and all four focused cases keep `transport_temperature_offset_fraction >> 1`.

Why this mattered:

- it removes the old bridge-dominated temperature interpretation from the live bundle,
- it keeps the split semantics explicit: temperature is photospheric while pressure and optical-depth helpers still reference the deeper matching concept,
- and it leaves the remaining sharp owner on the surface pressure row rather than on the temperature helper.

Verification run:

- `~/.juliaup/bin/julia --project=. scripts/run_surface_temperature_semantics_audit.jl artifacts/validation/2026-03-30-surface-temperature-semantics-audit`
- `~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_surface_temperature_semantics_audit_artifacts.jl"); include("test/test_docs_structure.jl")'`

What this does not prove:

- robust convergence,
- that Hopf is needed,
- or that the deeper matching layer is already correct.

Next step:

- keep the corrected photospheric temperature owner fixed, and inspect the surviving `surface_pressure` semantics before widening scope to richer atmosphere models.

### Surface temperature semantics audit

ASTRA's rebuilt `2026-03-30-surface-temperature-semantics-audit` bundle now records the live semantics of the corrected surface-temperature row in the same focused four-case view. The structural pattern is consistent in every focused payload: `match_to_photosphere_log_gap` is zero, `surface_to_match_log_gap` stays small and positive, and `transport_temperature_offset_fraction` remains far above unity. In plain language, the live temperature owner is now photospheric across the focused bundle, while the remaining sharp surface owner is `surface_pressure`.

Measured post-fix facts:

- all four focused cases are still `converged = false`,
- all four focused cases still have `used_regularized_fallback = true`,
- all four focused cases keep `accepted_dominant_surface_family = surface_pressure`,
- all four focused cases satisfy `match_to_photosphere_log_gap = 0.0`,
- and all four focused cases keep `transport_temperature_offset_fraction >> 1`.

Why this mattered:

- it distinguishes a photospheric temperature owner from the remaining surface-pressure mismatch,
- it gives the next slice a sharper scientific target than the broader `surface_temperature` label alone,
- and it does so without changing solver behavior.

Verification run:

- `~/.juliaup/bin/julia --project=. scripts/run_surface_temperature_semantics_audit.jl artifacts/validation/2026-03-30-surface-temperature-semantics-audit`
- `~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_surface_temperature_semantics_audit_artifacts.jl"); include("test/test_docs_structure.jl")'`

What this does not prove:

- robust convergence,
- that Hopf is needed,
- or that the current bridge semantics are correct.

Next step:

- keep the corrected Eddington-grey photosphere and the one-sided outer transport row fixed, and test the surviving `surface_pressure` semantics directly before widening scope to richer atmosphere models.

### Surface owner localization audit

ASTRA's rebuilt `2026-03-30-surface-owner-localization-audit` bundle now records the live post-temperature-fix state in a focused four-case view. Unlike the earlier mixed ownership story, all four focused cases now accept on `surface` with `accepted_dominant_surface_family = surface_temperature`, and the outer transport hotspot stays on the outer row at cell index `11`. The focused bundle therefore says something sharper than the pre-cutover audit did: under the corrected temperature owner, the surviving near-surface failure is temperature-dominated in this four-case bundle.

Measured post-fix facts:

- all four focused cases are still `converged = false`,
- all four focused cases still have `used_regularized_fallback = true`,
- `default-12` has `accepted_step_count = 8`, `rejected_trial_count = 680`, `final_weighted_residual_norm = 0.812065048601674`, and `final_merit = 16.48624107901098`,
- all four focused cases have `accepted_dominant_surface_family = surface_temperature`,
- all four focused cases keep the outer transport hotspot on the outer row at cell index `11`,
- and in every focused payload the magnitude ordering stays the same: `|surface_temperature_weighted| > |surface_pressure_weighted| > |outer_transport_weighted|`.

Why this mattered:

- it separates the live post-fix state from the earlier historical mixed-ownership audit,
- it shows that the remaining focused failure is no longer split between `surface_pressure` and `surface_temperature`,
- and it gives the next slice a sharper owner without pretending the solve is healthy.

Verification run:

- `~/.juliaup/bin/julia --project=. scripts/run_surface_owner_localization_audit.jl artifacts/validation/2026-03-30-surface-owner-localization-audit`
- `~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_surface_owner_localization_audit_artifacts.jl"); include("test/test_docs_structure.jl")'`

What this does not prove:

- robust convergence,
- that Hopf is needed,
- or that the outer transport row has stopped mattering.

Next step:

- keep the corrected Eddington-grey temperature owner fixed, and inspect the live `surface_temperature` semantics before widening scope to richer atmosphere models.

### Bridge outer temperature through fitting point

ASTRA now keeps the Eddington-grey photosphere at `tau = 2/3`, but the live outer-cell temperature owner no longer continues that atmosphere directly to `tau = 2/3 + tau_half`. Instead, `outer_match_temperature_k(...)` now uses the local fitting-point bridge, so the live `outer-boundary-fitting-point-ownership` helper gaps are both code-identical: `temperature_contract_log_gap = 0.0` and `pressure_contract_log_gap = 0.0` on `default-12`. In other words, the live code path now does exactly what the slice title says: bridge outer temperature through fitting point.

Measured post-cutover result:

- the default solve is still `converged = false`,
- the dominant surface family is `surface`,
- the final weighted residual norm is `0.812065048601674`,
- the final surface-family merit is `15.1493621034566`,
- and the outer-transport family merit is `0.4946980185677376`.

Why this mattered:

- it removes the old live helper-gap disagreement on the temperature side instead of leaving the current code half-Eddington and half-fitting-point,
- it makes the current surface closure say one thing physically instead of two,
- and it sharpens the next scientific question: not "is the temperature helper mismatched?" but "why is the solve still surface-owned after that mismatch is removed?"

Verification run:

- `~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_outer_boundary_fitting_point_terms.jl"); include("test/test_atmosphere_match_point.jl")'`
- `~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_boundary_conditions.jl"); include("test/test_outer_boundary_row_diagnostics.jl"); include("test/test_solver_progress_diagnostics.jl"); include("test/test_docs_structure.jl")'`

What this does not prove:

- robust convergence,
- that a Hopf atmosphere is needed,
- or that the remaining failure lives only in the temperature owner.

Next step:

- keep the Eddington-grey photosphere, keep the pressure bridge exact, and inspect why the live solve is still surface-owned before widening scope to richer atmosphere models.

### Outer boundary fitting-point ownership audit

ASTRA's refreshed `2026-03-30-outer-boundary-fitting-point-ownership-audit` bundle separates the pressure bridge from the temperature bridge. Every payload in the focused bundle is still `converged = false` and `used_regularized_fallback = true`. In `default-12`, `pressure_contract_log_gap = 0.0` while `temperature_contract_log_gap = -2.599766419592937`, and the accepted dominant surface family is `surface_pressure`. The perturbation cases stay mixed: `perturb-a1e-6-case-01` and `perturb-a1e-6-case-03` accept on `surface_temperature`, `perturb-a1e-6-case-02` accepts on `surface_pressure`, and the accepted transport hotspot still sits on the outer row at cell index `11`.

Why this mattered:

- it records the current `outer-boundary-fitting-point-ownership` interpretation as a mixed bridge story instead of a single outer-boundary lump,
- it treats the pressure bridge as code-identical because both sides use the same `P_ph + g σ_half` bridge, so the zero gap deprioritizes pressure-bridge-gap ownership without independently validating pressure semantics,
- and it leaves the temperature bridge mismatch as the sharper remaining non-pressure candidate.

Verification run:

- `~/.juliaup/bin/julia --project=. scripts/run_outer_boundary_ownership_audit.jl artifacts/validation/2026-03-30-outer-boundary-fitting-point-ownership-audit`
- `~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_docs_structure.jl")'`

What this does not prove:

- a solver rewrite,
- a parity claim,
- or that the temperature bridge alone explains the outer-boundary behavior.

Next step:

- keep the pressure bridge exact, keep the temperature bridge under targeted review, and do not widen scope into adaptive regularization from this evidence alone.

### Outer surface coupling audit evidence

ASTRA's refreshed `2026-03-30-outer-surface-coupling-audit` bundle sharpens the remaining near-surface diagnosis after the transport sign contract correction. In `default-12`, the accepted and best-rejected dominant surface family is `surface_pressure`, the accepted transport hotspot still sits on the outer row at cell index `11`, and the accepted outer-boundary summary reports `outer_transport_weighted = 0.8444699228014957`, `surface_temperature_weighted = 0.6854069474453723`, `surface_pressure_weighted = -0.7960701554689767`, `match_temperature_k = 1.1733423492649216e6`, and `match_pressure_dyn_cm2 = 3.9370078676338625e13`.

Why this mattered:

- it makes the `dominant surface family` and `best rejected dominant surface family` explicit rather than collapsing the surface rows into one bucket,
- it shows the outer boundary remains active while the surface pressure row is the sharpest current near-surface owner on the default fixture,
- and it also shows the bundle is mixed, not singular: the perturbation cases split between `surface_pressure` and `surface_temperature`, so the audit sharpens the target without proving a one-row-only fix.

Verification run:

- `~/.juliaup/bin/julia --project=. scripts/run_armijo_merit_validation.jl artifacts/validation/2026-03-30-outer-surface-coupling-audit`
- `~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_docs_structure.jl")'`

What this still does not prove:

- every payload is still `converged = false`,
- `used_regularized_fallback = true` remains present everywhere,
- and the bundle does not yet establish whether the next solver change should land in pressure-match semantics, temperature attachment semantics, or the outer transport stencil itself.

Next step:

- treat `surface_pressure` as the current sharpest default-12 owner, but keep the evidence mixed across perturbations and continue with surgical diagnostics rather than a broad conditioning rewrite.

### Transport sign contract correction evidence

ASTRA's refreshed `2026-03-30-transport-sign-correction` artifact bundle now records what changes once the transport sign contract is made physically consistent across code, tests, and docs. The default-12 payload no longer peaks on a surface-adjacent interior transport row. Instead, the accepted transport hotspot moves to the outer row at cell index `11`, with `accepted_dominant_family = surface`, `accepted_transport_hotspot.weighted_contribution = 0.8444699228014957`, `final_weighted_residual_norm = 0.26449516386740546`, and `final_merit = 1.7489422927311415`.

Why this mattered:

- it corrects a structural transport sign contract mismatch rather than treating the old hotspot attribution as a pure conditioning fact,
- it shows the earlier surface-adjacent interior diagnosis was not stable under the corrected contract,
- and it gives the next hardening slice new evidence that outer and surface-coupled rows now deserve first inspection.

Verification run:

- `~/.juliaup/bin/julia --project=. scripts/run_armijo_merit_validation.jl artifacts/validation/2026-03-30-transport-sign-correction`
- `~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_docs_structure.jl")'`

What this still does not prove:

- every refreshed payload is still `converged = false`,
- `used_regularized_fallback = true` is still present everywhere in the refreshed bundle,
- most fixtures improve in weighted norm and merit, but `perturb-a1e-6-case-03` gets worse, so this is not a blanket solver-improvement claim,
- and the refreshed outer hotspot does not yet prove whether the scientific owner is the one-sided transport stencil, the surface attachment semantics, or surface-row scaling.

Next step:

- keep the transport sign contract explicit and use the refreshed bundle to harden the outer transport and surface-coupled rows before widening scope into another generic conditioning pass.

### Transport hotspot diagnostics

ASTRA's refreshed `2026-03-30-transport-hotspot-diagnostics` artifact bundle now records one explicit transport hotspot per payload: the transport row with the largest weighted contribution, together with its location and cell index. That turns the earlier blended family evidence into a row-level diagnosis. In the default-12 payload, the accepted transport hotspot is the surface-adjacent interior row at cell index `10`, with weighted contribution `-1.0085188425976508`. The smallest ladders still peak on the outer row, at cell index `5` for `cells-6` and `7` for `cells-8`.

Why this mattered:

- it sharpens the diagnosis beyond the earlier `interior_transport` versus `outer_transport` family split,
- it points the current bottleneck toward a surface-adjacent interior transport row rather than the one-sided outer row alone,
- and it gives the next transport-hardening slice a concrete target with both hotspot location and cell index evidence.

Verification run:

- `~/.juliaup/bin/julia --project=. scripts/run_armijo_merit_validation.jl artifacts/validation/2026-03-30-transport-hotspot-diagnostics`

What this still does not prove:

- the solve is still `converged = false` across the bundle,
- the hotspot evidence still does not isolate whether the near-surface interior row is failing because of transport-row physics, surface attachment semantics, or local nonlinearity,
- and regularized fallback is still present everywhere.

Next step:

- harden the surface-adjacent interior transport row and its interface to the surface closure before widening scope into another generic conditioning pass.

### MESA scaling audit and transport-hardening plan

ASTRA's methods pages now record a more precise file-backed MESA scaling comparison and a matching next-step implementation plan at `docs/plans/2026-03-30-transport-outer-boundary-hardening-implementation-plan.md`. The important correction is that MESA's useful pattern is layered conditioning, not merely "use `x_scale`": the local source shows per-variable scaling, equation-local normalization, and correction-domain guards. The corresponding ASTRA next move is to split interior and outer transport diagnostics, harden transport-local solver metrics, and add a narrow outer-boundary domain guard before widening scope into adaptive regularization.

Why this mattered:

- it keeps the methods record aligned with the actual MESA source instead of a hand-wavy "MESA-like" story,
- it records that ASTRA's log-basis variables already encode part of the scaling story, so a literal `x_scale` clone would be the wrong first move,
- and it turns the next transport/outer-boundary slice into an explicit, reviewable implementation plan instead of an oral recommendation.

Verification run:

- `~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_docs_structure.jl")'`
- `cd /Users/anna/projects/julia-dev/astra/docs/website && myst build --site --html --strict`

Next step:

- execute `docs/plans/2026-03-30-transport-outer-boundary-hardening-implementation-plan.md` task-by-task and stop early if the split diagnostics point away from the outer boundary.

### Transport-family split validation evidence

The fresh `2026-03-30-transport-outer-boundary-hardening` artifact bundle now splits transport into `interior_transport` and `outer_transport`. The measured pattern is mixed rather than purely outer-boundary-local: `outer_transport` dominates the smallest `n_cells = 6, 8` runs, but `interior_transport` dominates the default-12 case, the larger-cell ladder, and most perturbation payloads. Every payload still reports `converged = false` and `used_regularized_fallback = true`, so the solve is not healthy yet, but the evidence now says the bottleneck is transport-family-local with a boundary sensitivity rather than a boundary-only failure.

Why this mattered:

- it sharpens the diagnosis beyond the earlier aggregate `transport` label,
- it prevents the website from overstating the outer boundary as the sole culprit,
- and it gives the next hardening slice a more honest target: mixed transport-family conditioning, not just a one-sided surface fix.

Verification run:

- `~/.juliaup/bin/julia --project=. scripts/run_armijo_merit_validation.jl artifacts/validation/2026-03-30-transport-outer-boundary-hardening`

Next step:

- keep the boundary contract explicit while hardening the transport-family rows against the mixed interior/outer failure signature.

### Armijo merit validation evidence

ASTRA now has a dated artifact bundle and interpretation note for the current Armijo merit validation sweep at `artifacts/validation/2026-03-30-armijo-merit-validation/` and `docs/website/development/armijo-merit-validation-2026-03-30.md`. The bundle covers the 6, 8, 12, 16, and 24 cell ladder plus the default-12 fixture and a deterministic perturbation family; every recorded payload is still `converged = false`, every accepted and best-rejected dominant family is `transport`, and regularized fallback appears in every payload.

Why this mattered:

- it turns the validation sweep into durable evidence instead of a terminal transcript,
- it makes the current bottleneck explicit enough to compare transport-row hardening against adaptive regularization later,
- and it gives the next numerical move a dated reference point that is tied directly to committed artifacts.

Verification run:

- `~/.juliaup/bin/julia --project=. scripts/run_armijo_merit_validation.jl artifacts/validation/2026-03-30-armijo-merit-validation`

Next step:

- harden the transport/outer-boundary row family before revisiting adaptive regularization.

### Armijo merit globalization

ASTRA's classical Newton controller now uses Armijo sufficient decrease on the frozen-weight merit function rather than accepting any step with lower merit. The diagnostics surface also now reports predicted-versus-actual decrease, accepted-step row-family attribution, and the best rejected trial, while keeping the current correction limiter, raw-residual safeguard, and regularization ladder unchanged.

Why this mattered:

- it upgrades the controller from a merely explicit objective to a scientifically recognizable sufficient-decrease rule,
- it makes row-family failure modes much more attributable than the earlier initial/final-only summaries,
- and it creates the evidence surface ASTRA needs before deciding whether adaptive regularization should become solver-owned behavior.

Verification run:

- `~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_armijo_merit_diagnostics.jl"); include("test/test_solver_progress_diagnostics.jl")'`
- `~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_armijo_merit_acceptance.jl"); include("test/test_default_newton_progress.jl"); include("test/test_convergence_basin.jl")'`

What this still does not prove:

- the classical solve is still not converged on the default fixture,
- adaptive regularization remains deferred,
- and the new `rho` evidence still needs broader model-family coverage before ASTRA should claim mature globalization.

Next step:

- run the full regression and docs-build verification, then decide whether the next bottleneck is adaptive regularization or a row-family-local physics boundary issue.

### Minimal frozen-weight merit globalization

ASTRA's classical Newton controller now speaks in terms of one explicit frozen-weight merit function rather than only weighted-residual wording. The current controller still uses the existing correction limiter, the existing regularization ladder, and the existing raw-residual safeguard, but the accepted-step decision is now described and recorded as merit decrease. The diagnostics object also now exposes merit history plus initial and final row-family merit summaries.

Why this mattered:

- it gives the current classical lane one declared solver objective without changing the packed basis or luminosity ownership,
- it makes the controller diagnostics more interpretable than the old weighted-norm-only wording,
- and it lands the smallest honest merit slice while keeping predicted-versus-actual decrease and richer row-family attribution explicitly deferred.

Verification run:

- `~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_merit_globalization_metrics.jl"); include("test/test_solver_progress_diagnostics.jl")'`
- `~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_merit_globalization_acceptance.jl"); include("test/test_default_newton_progress.jl"); include("test/test_convergence_basin.jl")'`

What this still does not prove:

- the classical solve is still not converged on the default fixture,
- predicted-versus-actual decrease remains deferred,
- and row-family diagnostics are still only initial/final merit summaries rather than full rejected-trial attribution.

Next step:

- run the full required regression and docs-build verification, then refresh any measured benchmark numbers that changed.

### Phase 2 atmosphere contract recorded

ASTRA's atmosphere slice now records the one-sided Phase 2 `T(\tau)` contract directly in the website. The current classical lane still keeps the outer radius and luminosity target rows, preserves the packed structure basis `[\ln R, L, \ln T, \ln \rho]`, and the surface thermodynamic rows use the shared outer match-point helper layer while the outer transport row remains one-sided to the photospheric face. The surface pressure scale also uses the shared outer match-point pressure scale.

Why this mattered:

- it separates the atmosphere question from the future global-closure question,
- it records the now-implemented helper-layer update honestly on the website,
- and it gives the next validation work a stable scientific target.

Verification run:

- `~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_docs_structure.jl")'`
- `cd /Users/anna/projects/julia-dev/astra/docs/website && myst build --site --html --strict`

Next step:

- document the convergence-basin behavior once the Phase 2 atmosphere slice is exercised more broadly.

### Atmosphere boundary hardening

ASTRA's classical lane now uses a one-sided Phase 2 Eddington `T(\tau)` atmosphere closure at the surface. The outer radius and luminosity target rows remain in place, the surface temperature row is tied to the shared outer match-point temperature helper, the surface pressure row is tied to the shared outer match-point pressure helper, and the outer transport row remains one-sided to the photospheric face. The solver-side row weights were also realigned so the surface temperature row is dimensionless and the surface pressure row is weighted on the shared outer match-point pressure scale.

Why this mattered:

- it replaces the provisional hard surface temperature/density guesses with a physically interpretable atmosphere closure,
- it keeps the outer transport row one-sided to the photospheric face while matching the surface thermodynamic rows through the same atmosphere semantics,
- and it fixes the weighted acceptance metric so it judges the new pressure row against the same outer match-point pressure scale instead of the old density units.

Verification run:

- `~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_boundary_conditions.jl")'`
- `~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_outer_transport_boundary.jl"); include("test/test_jacobian_fidelity_audit.jl")'`
- `~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_solver_progress_diagnostics.jl"); include("test/test_default_newton_progress.jl"); include("test/test_convergence_basin.jl")'`

What this still does not prove:

- the solver still has a large rejected-trial count even though it now makes accepted progress again,
- and the docs/validation surfaces still need a broader convergence-basin follow-up.

Next step:

- record the current atmosphere boundary and solver-metric state as the baseline for convergence-basin work.

### Weighted solver metrics and safeguarded acceptance

ASTRA's classical solver now carries explicit row weights, explicit correction weights, weighted correction limiting, weighted residual histories, and weighted correction histories. The nonlinear controller now accepts a step only if the weighted residual metric decreases and the raw residual norm does not increase.

Why this mattered:

- it makes solver control explicit instead of burying conditioning in an accidental mix of units,
- it keeps luminosity linear in physical `erg/s` while still giving Newton a dimensionless correction metric,
- and it exposed an important design detail early: a weighted-only acceptance rule was too permissive, so the accepted slice freezes the current iterate's weighting during trial comparison and keeps a raw-residual safeguard for scientific honesty.

Verification run:

- `~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_weighted_solver_metrics.jl")'`
- `~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_default_newton_progress.jl"); include("test/test_solver_progress_diagnostics.jl")'`
- `~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_jacobian_fidelity_audit.jl"); include("test/test_convergence_basin.jl")'`

What this still does not prove:

- the classical solve is still not converged on the default fixture,
- the weighting policy is still only benchmarked on the current toy-problem family,
- and ASTRA still does not have a full merit-function line search or trust-region controller.

Next step:

- document the weighted-metrics slice and then decide whether the next numerical move should be better weighting policy, stronger predicted-versus-actual decrease diagnostics, or a first merit-function globalization prototype.

## 2026-03-29

### State/model contract refactor

ASTRA's bootstrap code now exposes an explicit `StellarModel` with `StructureState`, `CompositionState`, and `EvolutionState` blocks. The nonlinear solve path now mutates only the structure block, while composition and evolution remain persistent model-owned state.

Why this mattered:

- it makes ownership visible in code rather than only in design notes,
- it keeps the solve vector on the narrow classical structure slice,
- and it gives future hydrostatic work a cleaner foundation than the old flat-state scaffold.

Verification run:

- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'`
- `~/.juliaup/bin/julia --project=. scripts/run_examples.jl`
- `cd docs/website && myst build --site --html --strict`

Next step:

- implement the real classical baseline residual and closure contracts without expanding beyond the approved solar-first scope.

### First classical residual minimal slice

ASTRA now assembles a first classical residual on `StellarModel` rather than comparing against an analytic reference profile. The code now carries real center rows, real interior structure rows, and a minimal physical surface closure, while still using placeholder EOS, opacity, nuclear, and convection layers.

Why this mattered:

- it moves the solver and Jacobian onto the right equation semantics,
- it proves the current ownership contract can support real residual assembly,
- and it keeps the remaining scientific gaps explicit instead of hiding them behind a pedagogical scaffold.

Verification run:

- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'`
- `~/.juliaup/bin/julia --project=. scripts/run_examples.jl`
- `cd docs/website && myst build --site --html --strict`

Next step:

- tighten closure fidelity and initialization quality without pretending that the current placeholder microphysics or provisional surface closure are already solar-ready.

### Classical convergence-basin tightening

ASTRA's default classical solve now starts from a geometry-consistent radius/density seed, a source-matched toy luminosity profile, and a surface-anchored temperature profile. That reduces the default residual norm from the old `~1e33` regime into the `~1e22` regime for the bootstrap examples and adds explicit diagnostics notes about the initialization and bounded step logic.

Why this mattered:

- it makes the default solve measurably less degenerate without adding new physics or new solver packages,
- it keeps the caveat visible that the seed is numerically helpful rather than physically calibrated,
- and it gives the later Jacobian work a cleaner starting point than the singular old seed.

Verification run:

- `~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_convergence_basin.jl")'`
- `~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_solve_contract.jl"); include("test/test_convergence_basin.jl")'`
- `~/.juliaup/bin/julia --project=. scripts/run_examples.jl`

Next step:

- add local derivative validation for classical helper kernels before replacing the global finite-difference Jacobian.

### Classical baseline next-steps close-out

ASTRA has now completed the four planned implementation slices for this round:

- the default classical seed lands in a materially better residual basin,
- one local helper derivative is validated against finite differences,
- the nonlinear solve now consumes a block-aware Jacobian path rather than the old global dense finite-difference builder,
- and `solve_structure(problem; state = guess)` is spelled out as the current public solve boundary for future sensitivities.

Why this mattered:

- it turns the classical lane into a more falsifiable baseline for later science work,
- it makes the derivative story explicit at both the helper and solve-boundary levels without overselling sensitivity readiness,
- and it keeps ASTRA's current limitations visible instead of hiding them behind aspirational architecture language.

Verification run:

- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'`
- `~/.juliaup/bin/julia --project=. scripts/run_examples.jl`
- `cd docs/website && myst build --site --html --strict`

What this still does not prove:

- the classical nonlinear solve still does not converge on the toy examples,
- the block-aware Jacobian is still partly local finite-difference fallback rather than fully analytic,
- and no implicit sensitivity rule or solver-aware AD integration has landed yet.

Next step:

- make the classical Newton update actually converge from the improved seed, with the next blocker now centered on update quality and Jacobian fidelity rather than on missing ownership, helper, or API contracts.

### Default Newton progress reporting

ASTRA's public default classical solve now reports real Newton-progress evidence instead of the old iteration-0 stall story. The default 24-cell example takes one accepted step, lowers the residual norm from `1.5669943212166535e22` to `1.5669942857059996e22`, records `219` rejected trials, and reports damping history explicitly as `[0.001953125]`.

Why this mattered:

- it makes the public example and docs consistent with the verified solver behavior,
- it keeps the one-step progress claim falsifiable instead of hand-wavy,
- and it shows that the remaining blocker is narrow-step update quality rather than missing progress diagnostics.

Verification run:

- `~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_default_newton_progress.jl")'`
- `~/.juliaup/bin/julia --project=. scripts/run_examples.jl`

What this still does not prove:

- the solve still does not reach `converged = true`,
- the accepted-step residual history is monotonic so far only in the trivial sense that there is one accepted step,
- this is not yet evidence of robust basin control,
- and the Jacobian/update direction is still weak enough to require very heavy regularization and many rejected trials.

Next step:

- run the full package/docs verification and then record the slice as provisional, with Jacobian fidelity and stronger globalization still the next numerical bottleneck.

### Center asymptotics and luminosity conditioning

ASTRA's current classical slice now conditions the luminosity columns in the Newton solve and replaces the old innermost shell-volume / zero-luminosity center closure with leading-order center asymptotic targets. The default 24-cell example still does not converge, but it now lowers the residual norm from `2.1962008371612166e22` to `2.1275638477172188e22`, accepts one step with damping `[0.03125]`, and keeps the initialized center luminosity consistent with the local source target to machine precision.

Why this mattered:

- it removes a real center-path fragility from the first zone rather than asking Float64 to resolve a subtractive-cancellation boundary row,
- it conditions the mixed `log(...)` / raw-`L` solve vector without changing solver-owned physical luminosity units away from `erg/s`,
- and it gives the current default Newton path a materially larger residual-reducing step on the same placeholder-closure stack.

Verification run:

- `~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_center_asymptotic_scaling.jl")'`
- `~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_boundary_conditions.jl")'`
- `~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_block_jacobian.jl")'`
- `~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_solver_progress_diagnostics.jl"); include("test/test_default_newton_progress.jl")'`
- `~/.juliaup/bin/julia --project=. scripts/run_examples.jl`

What this still does not prove:

- the classical nonlinear solve is still not converged on the public examples,
- the current center asymptotic form is a bootstrap-level leading-order fix rather than a full physically mature central expansion scheme,
- and the Jacobian/update path is still weak enough to require heavy retrying even after scaling.

Next step:

- audit the Jacobian blocks and regularization path that still force the solver into one accepted step plus hundreds of rejected trials.

### Jacobian fidelity audit

ASTRA's classical Jacobian now carries explicit local partials for the center radius/luminosity rows and the interior geometry/luminosity rows, while the remaining hydrostatic and transport rows stay on a block-local central-difference fallback path. The default 24-cell public example now takes `8` accepted Newton steps, lowers the residual from `2.1962008371612166e22` to `1.1903032914682583e19`, and reduces rejected trials from the old `380` regime down to `289`.

Why this mattered:

- it replaced the cleanest residual rows with exact local derivatives that are now validated against independent local finite differences,
- it kept the remaining fallback rows narrow and explicit instead of pretending the whole Jacobian is analytic already,
- and it improved the public Newton trajectory without changing the physics stack, solve boundary, or outer nonlinear algorithm.

Verification run:

- `~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_local_derivative_validation.jl")'`
- `~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_jacobian_fidelity_audit.jl")'`
- `~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_block_jacobian.jl"); include("test/test_default_newton_progress.jl")'`
- `~/.juliaup/bin/julia --project=. scripts/run_examples.jl`

What this still does not prove:

- the public examples still do not reach `converged = true`,
- hydrostatic, transport, and surface rows are still not on a fully analytic Jacobian path,
- and this remains a placeholder-microphysics bootstrap lane rather than a trustworthy solar model.

Small correction applied during this slice:

- a full analytic replacement of the interior hydrostatic and transport rows regressed the 24-cell public example, so the accepted implementation keeps those rows on block-local central-difference fallback while retaining the exact center/geometry/luminosity rows.

Next step:

- tighten the remaining fallback rows or the physical closure stack in a way that is checkpointed against the stronger multi-step public Newton path, rather than reverting to one-step progress claims.
