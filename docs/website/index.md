# ASTRA

**ASTRA** is the **Adaptive STellar Research Architecture**: a Julia-native framework for stellar structure and evolution designed around **clarity, modular physics, solver ownership, validation, and controlled method development**.

ASTRA is built on a simple premise: modern stellar astrophysics needs more than a legacy black box. It needs an architecture that makes the physics explicit, keeps the numerics inspectable, and supports careful movement from classical baselines to more advanced formulations.

ASTRA therefore begins with a deliberate goal: build a **trustworthy classical stellar-structure baseline** first, then use that baseline as the foundation for validation, comparison, and later extensions in time evolution, alternative formulations, and differentiable methods.

This site is part handbook, part design record, and part scientific guide. It has four jobs at once:

- orient new contributors,
- explain the scientific and numerical architecture,
- preserve design memory,
- and teach the physics and methods behind the code.

## What ASTRA is for

ASTRA is a **research framework** for building stellar structure and evolution in a way that is:

- **modular**, so physics and numerics can evolve without collapsing into a monolith,
- **validation-ready**, so each scientific step can be checked against known baselines,
- **solver-aware**, so numerical methods are part of the design rather than hidden implementation detail,
- and **future-facing**, so later work in differentiable methods and alternative formulations can grow from a trusted foundation.

The first major milestone is a robust classical Henyey-style solver. That solver is not the endpoint. It is the reference surface against which more experimental approaches, including Entropy-DAE and differentiable workflows, can be developed and judged.

ASTRA is intentionally scoped for disciplined growth: a clean baseline first, then controlled expansion in physics, methods, and formulation.

## Why This Architecture Matters

At the core of ASTRA is a strict separation of concerns:

- [Physics](physics/index.md) explains what equations and closures define the star,
- [Methods](methods/index.md) explains how those equations become a nonlinear solve,
- [Validation](validation/philosophy.md) explains what is actually proven,
- [Planning](planning/roadmap.md) explains how ASTRA moves from bootstrap to a validated classical lane and then to more advanced formulations.

That separation is not cosmetic. It is what makes ASTRA understandable, testable, extensible, and eventually differentiable in a controlled scientific way.

## How to Use This Site

- Start with [Getting Started](getting-started/installation.md) if you want to install Julia, run the scaffold, and inspect the package layout.
- Read [Architecture](architecture/overview.md) if you want to understand how ASTRA separates physics, numerics, and orchestration.
- Read [Physics](physics/index.md) and [Methods](methods/index.md) if you want the exact equations, residuals, Jacobians, and boundary-condition realization that the code is currently using.
- Read [Validation](validation/philosophy.md) if you want to know what the current scaffold demonstrates, what remains provisional, and how scientific trust is being built.
- Read [Planning](planning/roadmap.md) if you want the development sequence from bootstrap to classical baseline and then to more advanced formulations.
- Read [Development](development/development-guide.md) if you want to see what is implemented, what is blocked, and what comes next.

If you are new to the repository, read the site in that order. The ASTRA docs are meant to teach not just where the files live, but how to think about the codebase.

## Current Status

The current repository is at the bootstrap stage:

- package scaffold,
- classical toy residual and Jacobian path,
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
