# Package Layout

ASTRA is deliberately a single root Julia package rather than a workspace of many small packages. For a young scientific code, that choice keeps the public surface easier to understand. Julia already gives strong structure through modules, files, and explicit imports, so ASTRA can teach ownership without adding package-level sprawl.

## Why one package first

For a new contributor, a **package** is just the named project Julia loads when you write `using ASTRA`. Inside that package, files and submodules divide responsibility. ASTRA starts with one package because the main challenge right now is scientific clarity, not multi-package distribution strategy.

One package also keeps the development loop simple: one environment, one public entry point, and one place to look when you are asking "where does this responsibility live?" Within that package, ASTRA groups most source files into small directories once they form a real conceptual layer.

That grouping is not just tidiness. In a scientific code, the source tree should teach the architecture. A student should be able to look at `src/` and see the main layers of thought in the code: foundation, microphysics, numerics, formulations, solvers, and evolution.

This matters because modular structure keeps changes local. If you are improving a closure, you should mostly live in `microphysics/`. If you are changing equation assembly, you should mostly live in `numerics/`. If every change starts by scanning a flat directory full of unrelated files, the codebase stops teaching and starts hiding.

## Layout map

- `src/ASTRA.jl` defines the top-level module, exports the public names, and wires the major subsystems together. Read this first when you want the map of the package.
- `src/foundation/` holds the foundation layer: constants, unit conventions, configuration, grids, core types, and state construction. This is the place to read when you want to know what the model is and how it is represented.
- `src/microphysics/` holds local closure models such as the EOS, opacity, nuclear heating, and convection hooks. These files answer local physics questions. They do not own the global solve.
- `src/numerics/` holds the equation layer: boundary conditions, structure-equation helpers, residual assembly, Jacobian assembly, and diagnostics. This is where ASTRA turns physics into a discrete nonlinear system.
- `src/solvers/` holds the nonlinear and linear solve logic that acts on those numerics-owned operators. In plain language, this layer decides how ASTRA tries to solve the equations.
- `src/formulations/` holds the formulation layer: the place where ASTRA chooses which mathematical approach is being used for a solve, such as the classical baseline or a later alternative formulation.
- `src/evolution/` is the explicitly deferred time-dependent layer. It exists so timestep-aware logic has a clear future home instead of leaking into the structure solve.

The key lesson of this layout is simple: the directory tree is trying to teach ownership before it teaches cleverness.

## How to use this layout as a contributor

When you add or change code, start with the question "what layer owns this responsibility?" before you ask "which file should I edit?"

- If you are defining data structures, grids, or pack/unpack rules, start in `foundation/`.
- If you are writing a local physics rule, start in `microphysics/`.
- If you are expressing an equation, a boundary row, or a Jacobian block, start in `numerics/`.
- If you are changing Newton steps, damping, or linear solves, start in `solvers/`.
- If you are adding a new mathematical lane, start in `formulations/`.
- If you are adding timestep-aware updates, start in `evolution/`.

That habit matters because modular code is not just easier to navigate. It is easier to validate, easier to teach, and much harder to let ownership boundaries silently collapse.

## Layout checklist

- [x] The page explains why ASTRA is one package before it names files.
- [x] The page explains why the source tree is grouped into layers instead of left flat.
- [x] The layout map connects directories to responsibilities, not just filenames.
- [x] `src/ASTRA.jl` is described as the public module entrypoint.
- [x] Physics, numerics, formulations, and evolution are given separate homes.
- [x] Foundation and numerics are visible as real source-tree layers rather than as flat-file clutter.
- [x] The page gives contributors a practical rule for deciding where new code belongs.
- [x] The page keeps the package story tied to ASTRA's architecture rather than generic Julia advice.
