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
