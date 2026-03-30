# ASTRA

**ASTRA** is the **Adaptive STellar Research Architecture**: a Julia-native framework for stellar structure and evolution designed around **clarity, modular physics, solver ownership, validation, and disciplined method development**.

ASTRA is built on a simple premise: modern stellar astrophysics needs more than a legacy black box. It needs a framework where the physics is explicit, the numerical methods are inspectable, and new formulations can be developed against a trusted baseline rather than buried inside inherited complexity.

Stars are already difficult enough. The software does not need to be mysterious too.

ASTRA therefore begins with a deliberate goal: build a **trustworthy classical stellar-structure baseline** first, then use it as the foundation for validation, comparison, and later extensions in time evolution, alternative formulations, and differentiable methods.

This site is part handbook, part design record, and part scientific guide: a place to orient contributors, explain the scientific and numerical architecture, preserve design memory, and teach the physics and methods behind the code.

## What ASTRA is for

ASTRA is a **research framework** for building stellar structure and evolution in a way that is:

- **modular**, so physics and numerics can evolve without collapsing into a monolith,
- **validation-ready**, so each scientific step can be checked against known baselines,
- **solver-aware**, so numerical methods are part of the design rather than hidden implementation detail,
- and **future-facing**, so differentiable methods, alternative formulations, and inference-ready workflows can grow from a trusted scientific foundation.

The first major milestone is a robust classical Henyey-style solver. That solver is not the endpoint. It is the scientific baseline against which more experimental approaches, including Entropy-DAE and differentiable workflows, can be developed and judged.

ASTRA is intentionally scoped for disciplined growth: a clean baseline first, then controlled expansion in physics, methods, and formulation.

## Why This Architecture Matters

At the core of ASTRA is a strict separation of concerns:

- [Physics](physics/index.md) explains what equations and closures define the star,
- [Methods](methods/index.md) explains how those equations become a nonlinear solve,
- [Validation](validation/philosophy.md) explains what is actually proven,
- [Planning](planning/roadmap.md) explains how ASTRA moves from bootstrap to a validated classical lane and then to more advanced formulations.

That separation is not cosmetic. It is what makes ASTRA understandable, testable, extensible, and eventually differentiable in a controlled scientific way.

The deeper ambition is not just cleaner code. It is to modernize stellar modeling software architecture so that equations, closures, solver choices, and validation claims can all be inspected in the same place and judged against the same scientific standard.

## How to Use This Site

For a first pass through the project, use this route:

- [Getting Started](getting-started/installation.md): install Julia, run the scaffold, and inspect the package layout.
- [Architecture](architecture/overview.md): understand how ASTRA separates physics, numerics, and orchestration.
- [Physics](physics/index.md) and [Methods](methods/index.md): read the current equations, residuals, Jacobians, and boundary-condition realization.
- [Validation](validation/philosophy.md): see what is established, what is provisional, and what is still stubbed.
- [Planning](planning/roadmap.md): follow the development sequence from bootstrap to classical baseline and then to more advanced formulations.
- [Development](development/development-guide.md): check implementation status, active blockers, and next steps.

New contributors should read the site in that order. The ASTRA docs are meant to teach not just where the files live, but how to think about the codebase.

## Current Status

The repository is still in its bootstrap stage:

- package scaffold,
- early classical residual and Jacobian prototype,
- tests and examples,
- MyST documentation system,
- formulation scaffolding,
- and explicit documentation of what is real, provisional, and stubbed.

The next major scientific milestone is the **validated classical baseline solver**. That is the point where ASTRA begins to transition from architectural scaffold to trusted stellar-structure engine.

## Long-Term Direction

ASTRA is not trying to do everything at once. It is trying to do one thing correctly at a time while building toward a future where stellar astrophysics can be treated as a constrained system that is not only solved, but eventually analyzed, differentiated, and used for inference.

That long-term direction includes:

- stronger classical validation,
- alternative formulations,
- differentiable solver boundaries,
- and the scientific infrastructure needed for inference-ready stellar modeling.

ASTRA's long-term direction is not just broader physics coverage. It is a modern scientific architecture for stellar modeling: one that can be solved, validated, extended, and eventually differentiated in a controlled way.
