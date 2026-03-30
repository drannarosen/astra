# ASTRA Scope Contract and Repository Specification

## Project Identity

**ASTRA** = **Adaptive STellar Research Architecture**

**Tagline:** *A modern Julia framework for stellar structure and evolution.*

## Mission

ASTRA is a **clean, modern, tightly scoped 1D stellar structure/evolution code in Julia**. Its purpose is to be:

1. a **strict forward-model laboratory** for stellar physics and numerics,
2. a **validation/reference engine** for ideas that may later inform Stellax,
3. a **beautifully documented, end-to-end understandable codebase**, and
4. a **method-comparison platform** where classical and novel formulations can be implemented and tested side by side.

ASTRA is **not** intended to become a MESA clone, a kitchen-sink community code, or a giant everything-engine. It should be intentionally smaller, stricter, clearer, and more internally coherent.

---

## Strategic Role Relative to Stellax

ASTRA and Stellax have different jobs.

### Stellax

* flagship differentiable stellar modeling code
* inference-native
* JAX-first
* gradients through the forward model are a core scientific differentiator

### ASTRA

* forward-model truth engine / numerical laboratory
* Julia-first
* clarity, solver quality, validation, and method comparison come first
* not required to be differentiable end-to-end in the initial phases

**ASTRA is a companion code, not a replacement for Stellax.**

---

## Core Scope Contract

### ASTRA must be

* **single-star**
* **1D**
* **spherically symmetric**
* **hydrostatic**
* **non-rotating**
* **non-magnetic**
* **modular**
* **test-driven**
* **well documented**
* **modern Julia**
* **forward-solver first**

### ASTRA must not initially become

* a MESA replacement
* a binary evolution code
* a population synthesis code
* a survey-inference engine
* a GPU-first framework
* a giant microphysics warehouse
* a feature farm with poorly validated physics

---

## Scientific Scope: What v0.x Covers

## Phase A — Baseline Forward Structure Solver

This is the first serious target.

### Physics included

* 1D spherical stellar structure
* hydrostatic equilibrium
* mass continuity
* energy transport
* luminosity/energy equation in a clean baseline form
* simple composition handling sufficient for initial experiments
* ideal gas + radiation pressure EOS baseline
* simple opacity model baseline
* simple nuclear energy generation baseline
* outer boundary condition with a clean, explicit prescription
* convection criterion hook, but initially minimal

### Physics deliberately excluded at first

* rotation
* magnetic fields
* binaries
* diffusion / settling / levitation
* overshoot
* semiconvection / thermohaline mixing
* mass loss
* neutrino cooling sophistication
* detailed reaction networks
* tabulated production microphysics
* atmosphere grids
* general relativity
* non-spherical structure
* oscillations / pulsations

### Deliverable

A converged hydrostatic stellar model with interpretable diagnostics and residuals.

---

## Phase B — Minimal Stellar Evolution

Only after Phase A is stable.

### Add

* time stepping
* simple composition evolution
* adaptive timestep control
* controlled state update / projection strategy
* production of simple evolutionary sequences

### Initial target

Generate **clean, scientifically interpretable toy evolutionary tracks**, not full MESA-parity stellar evolution.

---

## Phase C — Method Laboratory

Only after the classical baseline is trustworthy.

### Add

* alternative formulations
* side-by-side solver comparisons
* **Entropy-DAE as a novel formulation**
* benchmarking of conditioning, convergence, stability, and timestep behavior

**Entropy-DAE belongs in ASTRA, but ASTRA must not be defined solely by Entropy-DAE.**
ASTRA is the framework; Entropy-DAE is one of its flagship methods.

---

## Non-Goals

The following are explicitly out of scope for the initial repository build:

* full MESA feature parity
* detailed production microphysics tables on day one
* polished visualization platform
* giant I/O layer
* distributed multi-node architecture
* performance tuning for every edge case before correctness
* automatic support for every stellar regime
* “AI generated everything quickly” without tests and design discipline

---

## Design Philosophy

ASTRA should optimize for the following, in order:

1. **Correctness**
2. **Clarity**
3. **Validation**
4. **Extensibility**
5. **Performance**
6. **Feature growth**

That ordering is non-negotiable.

ASTRA should feel like:

* a code you can reason through end to end,
* a code where every module has a clean conceptual job,
* a code where adding physics does not destroy intelligibility,
* and a code where numerical experiments are easy to stage and compare.

---

## Repository Architecture

## Top-level structure

* `src/`
* `test/`
* `docs/`
* `examples/`
* `benchmark/`
* `scripts/`

## Package/module structure

### `src/ASTRA.jl`

Top-level module that assembles the public API.

### `src/foundation/constants.jl`

Physical constants and standard astrophysical reference values.

### `src/foundation/types.jl`

Core immutable structs and type definitions:

* stellar parameters
* mesh/grid types
* state vectors
* model containers
* solver options
* diagnostics containers

### `src/foundation/grid.jl`

Mesh generation and grid utilities.

### `src/foundation/state.jl`

Definition of the stellar state and pack/unpack utilities.

### `src/microphysics/`

Subdirectory containing:

* `eos.jl`
* `opacity.jl`
* `nuclear.jl`
* `convection.jl`

Each module must expose a narrow, explicit interface.

### `src/numerics/boundary_conditions.jl`

Surface/central boundary conditions.

### `src/numerics/residuals.jl`

Residual evaluation for the coupled stellar system.

### `src/numerics/jacobians.jl`

Jacobian assembly and Jacobian checks.

### `src/linear_solvers.jl`

Linear algebra utilities and structured solve hooks.

### `src/nonlinear_solvers.jl`

Newton, damping, convergence logic.

### `src/formulations/`

Subdirectory containing:

* `classical_henyey.jl`
* `entropy_dae.jl` (stub first, full implementation later)

### `src/evolution/`

Subdirectory containing:

* `timestepping.jl`
* `update.jl`
* `controllers.jl`

### `src/numerics/diagnostics.jl`

Residual norms, physical consistency checks, runtime summaries.

### `src/io.jl`

Minimal, disciplined I/O only. No giant serialization framework in v0.1.

---

## Public API Contract

The public API should be intentionally small.

Initial exported concepts should be limited to things like:

* build a model/config
* initialize a stellar state
* solve a structure model
* evolve one step
* run an example model
* inspect diagnostics

Do **not** expose a huge unstable API surface early.

Rule: **small public API, rich internal modularity.**

---

## Coding Contract

### General rules

* Julia `Float64` is the default numeric type.
* Hot kernels should be type-stable.
* Avoid abstractly typed containers in performance-critical paths.
* Avoid hidden allocations in tight loops.
* Use mutating `!` functions for in-place hot operations.
* Keep host-level orchestration readable and explicit.
* Prefer simple loops and clear kernels over clever abstractions.
* Every exported type/function must have a docstring.

### Architecture rules

* Separate **physics**, **numerics**, and **orchestration**.
* Microphysics modules must not secretly own solver logic.
* Solver modules must not hard-code one specific EOS/opacity choice.
* Formulations must be pluggable behind a stable interface.
* No monolithic “god file.”
* No hidden global state.

### AI coding rule

AI may generate code quickly, but **no code is accepted without**:

* tests,
* docstrings,
* basic validation,
* and a clear conceptual fit in the architecture.

---

## Validation Contract

ASTRA is not allowed to grow faster than it validates.

Every major feature must land with at least one of:

* analytic test
* regression test
* conservation/consistency test
* method-comparison test
* finite-difference Jacobian check

### Early validation targets

* hydrostatic balance residual sanity
* EOS consistency tests
* boundary-condition consistency tests
* Jacobian vs finite-difference spot checks
* convergence on simplified benchmark problems
* recovery of expected qualitative stellar-structure behavior

### Later validation targets

* simple evolutionary sequences
* cross-comparison of classical baseline vs Entropy-DAE
* comparison to trusted external reference solutions where appropriate

---

## Documentation Contract

ASTRA documentation must be part of the product, not an afterthought.

### Required docs

* project overview
* installation
* quickstart
* architecture overview
* physics overview
* numerics overview
* validation philosophy
* examples/tutorials
* developer guide

### Tone

The docs should read like a modern research software project:

* explicit assumptions
* variable definitions
* equation meaning
* formulation choices
* numerical reasoning
* no mystery interfaces

---

## Performance Contract

ASTRA should be written so it **can** be fast, but performance work follows correctness.

### Initial performance priorities

* type stability
* low allocation residual/Jacobian kernels
* structured linear algebra where appropriate
* clear profiling hooks
* no premature GPU abstraction

### Explicitly deferred

* heroic micro-optimization before validation
* complex GPU kernels in the bootstrap phase
* distributed scaling before a correct serial code exists

---

## Entropy-DAE Policy

Entropy-DAE is a major research direction, but ASTRA must not be architecturally held hostage by it.

### Rule

ASTRA must first support a **clean classical baseline formulation**.

### Then

Entropy-DAE can be introduced as:

* an alternative formulation,
* a research module,
* and a benchmarkable method.

### Scientific requirement

Entropy-DAE must be evaluated against the classical baseline on:

* convergence
* conditioning
* robustness
* timestep behavior
* physical diagnostics
* implementation complexity

This is essential for the science story.

---

## Milestones

## Milestone 0 — Repository Bootstrap

Goal:

* scaffold package
* docs build
* tests run
* examples directory exists
* CI runs
* formatting/linting baseline exists

## Milestone 1 — Baseline Physics Skeleton

Goal:

* constants, types, grid, state, microphysics stubs
* toy EOS/opacity/nuclear interfaces
* basic examples compile and run

## Milestone 2 — Hydrostatic Structure Solver

Goal:

* residual assembly
* Jacobian assembly
* nonlinear solve
* diagnostics
* first converged toy stellar model

## Milestone 3 — Clean Classical Framework

Goal:

* well-factored classical formulation
* stronger validation
* initial docs/tutorials
* stable public API for baseline solve

## Milestone 4 — Minimal Evolution

Goal:

* timestepper
* state updates
* adaptive control
* simple evolutionary sequence

## Milestone 5 — Entropy-DAE Experimental Formulation

Goal:

* implement Entropy-DAE behind formulation interface
* compare against classical baseline
* document differences and tradeoffs

---

## Definition of Done for the Initial Codex Build

Codex should not try to build the whole science code in one pass.

The **first repo deliverable** is complete only when:

* package scaffolding exists,
* the module tree matches the architecture above,
* the package imports cleanly,
* tests run successfully,
* docs build successfully,
* at least one toy example runs,
* stubs/interfaces are present for the core modules,
* and the architecture is clear enough for iterative scientific development.

That is the right first target.

---

## Hard Guardrails

ASTRA must not:

* become “MESA but smaller”
* absorb every interesting physics idea immediately
* add complex microphysics before baseline validation
* add GPU/distributed complexity too early
* let Entropy-DAE erase the existence of the classical baseline
* grow public API faster than documentation/tests
* sacrifice clarity for premature cleverness

---

## Short Mission Statement for README

**ASTRA is a modern Julia framework for stellar structure and evolution, designed as a strict forward-model laboratory for clean numerics, method development, and validation. It is intentionally narrower and more transparent than legacy kitchen-sink codes, and it serves as a companion forward engine to differentiable inference-first tools such as Stellax.**
