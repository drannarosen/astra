# Package Layout

ASTRA is deliberately a single root Julia package rather than a workspace of many small packages. For a young scientific code, that choice keeps the public surface easier to understand. Julia already gives strong structure through modules, files, and explicit imports, so ASTRA can teach ownership without adding package-level sprawl.

## Why one package first

For a new contributor, a **package** is just the named project Julia loads when you write `using ASTRA`. Inside that package, files and submodules divide responsibility. ASTRA starts with one package because the main challenge right now is scientific clarity, not multi-package distribution strategy.

One package also keeps the development loop simple: one environment, one public entry point, and one place to look when you are asking "where does this responsibility live?" Within that package, ASTRA now groups most source files into small directories once they form a real conceptual layer.

## Layout map

- `src/ASTRA.jl` defines the top-level module, exports the public names, and wires the major subsystems together.
- `src/foundation/` holds the foundation layer: constants, units, configuration, grids, core types, and state construction.
- `src/microphysics/` holds local closure models such as the EOS, opacity, nuclear heating, and convection hooks.
- `src/numerics/` holds the equation layer: boundary conditions, structure-equation helpers, residual assembly, Jacobian assembly, and diagnostics.
- `src/solvers/` holds the nonlinear and linear solve logic that acts on those numerics-owned operators.
- `src/formulations/` holds the formulation surface, meaning the place where ASTRA decides which mathematical lane is being used.
- `src/evolution/` is the explicitly deferred time-dependent layer. It exists so timestep-aware logic has a clear future home instead of leaking into the structure solve.

The key lesson of this layout is simple: the directory tree is trying to teach ownership before it teaches cleverness.

## Layout checklist

- [x] The page explains why ASTRA is one package before it names files.
- [x] The layout map connects directories to responsibilities, not just filenames.
- [x] `src/ASTRA.jl` is described as the public module entrypoint.
- [x] Physics, numerics, formulations, and evolution are given separate homes.
- [x] Foundation and numerics are visible as real source-tree layers rather than as flat-file clutter.
- [x] The page keeps the package story tied to ASTRA's architecture rather than generic Julia advice.
