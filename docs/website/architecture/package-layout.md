# Package Layout

ASTRA is deliberately a single root Julia package rather than a workspace of many small packages. For a young scientific code, that choice keeps the public surface easier to understand. Julia already gives strong structure through modules, files, and explicit imports, so ASTRA can teach ownership without adding package-level sprawl.

## Why one package first

For a new contributor, a **package** is just the named project Julia loads when you write `using ASTRA`. Inside that package, files and submodules divide responsibility. ASTRA starts with one package because the main challenge right now is scientific clarity, not multi-package distribution strategy.

One package also keeps the development loop simple: one environment, one public entry point, and one place to look when you are asking "where does this responsibility live?"

## Layout map

- `src/ASTRA.jl` defines the top-level module, exports the public names, and wires the major subsystems together.
- `src/constants.jl`, `src/config.jl`, `src/types.jl`, `src/grid.jl`, and `src/state.jl` form the foundation layer: basic types, configuration, grids, and state construction.
- `src/microphysics/` holds local closure models such as the EOS, opacity, nuclear heating, and convection hooks.
- `src/residuals.jl`, `src/jacobians.jl`, and `src/solvers/` hold the numerical layer: equations, derivative information, and nonlinear or linear solve logic.
- `src/formulations/` holds the formulation surface, meaning the place where ASTRA decides which mathematical lane is being used.
- `src/evolution/` is the explicitly deferred time-dependent layer. It exists so timestep-aware logic has a clear future home instead of leaking into the structure solve.

The key lesson of this layout is simple: the directory tree is trying to teach ownership before it teaches cleverness.

## Layout checklist

- [x] The page explains why ASTRA is one package before it names files.
- [x] The layout map connects directories to responsibilities, not just filenames.
- [x] `src/ASTRA.jl` is described as the public module entrypoint.
- [x] Physics, numerics, formulations, and evolution are given separate homes.
- [x] The page keeps the package story tied to ASTRA's architecture rather than generic Julia advice.
