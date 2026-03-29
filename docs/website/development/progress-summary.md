# Progress Summary

This page is ASTRA's dated executive journal. Each entry should be short enough to scan quickly, but concrete enough to tell a new contributor what really changed.

## Entry template

For each update, record:

- the date,
- the slice that landed,
- the main architectural or scientific consequence,
- the verification that was run,
- and the next intended step.

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
