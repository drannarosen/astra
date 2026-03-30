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
