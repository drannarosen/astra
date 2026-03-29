# Julia Dependency Strategy

This page records ASTRA's current package strategy as of **March 29, 2026**.

The guiding rule is simple:

> **Buy the generic Julia infrastructure. Build the stellar abstractions yourself.**

That means ASTRA should use the Julia ecosystem for package tooling, quality assurance, benchmarking, derivative helpers, and eventually solver interfaces, while keeping the meaning of the stellar model inside ASTRA's own types, residuals, formulations, diagnostics, and validation reports.

## The core ASTRA split

### ASTRA should own

- stellar state/data-model types,
- grid and pack/unpack logic,
- residual definitions,
- boundary-condition semantics,
- formulation interfaces,
- diagnostics and validation logic,
- any ASTRA-specific structured linear algebra.

### ASTRA should not build itself

- package scaffolding,
- formatter infrastructure,
- package QA tooling,
- benchmark harnesses,
- generic derivative libraries,
- generic nonlinear-solver frameworks,
- generic linear-solver abstraction layers,
- general-purpose documentation engines.

That split follows the current Julia ecosystem well: packages are modular, the SciML stack is designed as a composable solver ecosystem, and tooling around package QA and docs is mature enough that ASTRA does not gain much by reimplementing it. See the official pages for [PkgTemplates](https://juliaci.github.io/PkgTemplates.jl/stable), [Aqua](https://juliatesting.github.io/Aqua.jl/dev/), [Documenter](https://documenter.juliadocs.org/stable/), and the SciML solver stack such as [NonlinearSolve](https://docs.sciml.ai/NonlinearSolve/stable/) and [LinearSolve](https://docs.sciml.ai/LinearSolve/stable/).

## Use now

These are the packages ASTRA should feel comfortable adopting early, because they improve developer quality and local numerical verification without forcing ASTRA's scientific architecture to depend on them.

### Revise.jl

The official docs describe Revise as a way to keep Julia sessions running longer and pick up code edits in the next REPL command, including package changes and branch switches. That is a major quality-of-life win for ASTRA development, especially while iterating on types, residuals, and test cases.  
Source: [Revise.jl docs](https://timholy.github.io/Revise.jl/stable/) and specifically its introduction on session persistence and edit tracking.

### JuliaFormatter.jl

JuliaFormatter supports repository-level `.JuliaFormatter.toml` files and multiple house styles, including `blue`, `sciml`, and `yas`. ASTRA already has formatter config, so the next step is to treat formatting as policy rather than preference.  
Source: [JuliaFormatter configuration docs](https://domluna.github.io/JuliaFormatter.jl/stable/config/).

### Aqua.jl

Aqua explicitly automates package checks for ambiguities, undefined exports, stale dependencies, compat coverage, obvious type piracy, and related hygiene checks. That is almost exactly the checklist ASTRA should automate as the package gets more real.  
Source: [Aqua.jl home page](https://juliatesting.github.io/Aqua.jl/dev/).

### JET.jl

JET's docs show that it is built around Julia's type inference, with tools such as `@report_opt` to expose type instability and runtime dispatch. ASTRA cares deeply about type-stable hot paths, so JET is a natural fit for kernel hardening.  
Source: [JET.jl quickstart and `@report_opt`](https://aviatesk.github.io/JET.jl/dev/).

### BenchmarkTools.jl

BenchmarkTools remains the standard benchmarking package for Julia, and ASTRA will need it for residual kernels, Jacobian construction, and allocation tracking as soon as the classical solver exists.  
Source: [BenchmarkTools manual](https://juliaci.github.io/BenchmarkTools.jl/dev/manual/).

### ForwardDiff.jl

ForwardDiff officially supports derivatives, gradients, Jacobians, Hessians, and higher-order derivatives for native Julia functions using forward-mode AD. For ASTRA, that makes it a good local tool for EOS derivatives, block-level Jacobian checks, and small-scope prototypes.  
Source: [ForwardDiff introduction](https://juliadiff.org/ForwardDiff.jl/stable/).

### FiniteDiff.jl

FiniteDiff's docs emphasize numerical derivatives with multiple finite-difference schemes and cache support for repeated calculations. ASTRA should use finite differences for validation and debugging even if later Jacobian paths become analytic or AD-backed.  
Source: [FiniteDiff derivative docs](https://docs.sciml.ai/FiniteDiff/dev/derivatives/).

## Probably later

These packages are strong fits for ASTRA, but they should land only after the classical solver interfaces are more mature than the current bootstrap.

### NonlinearSolve.jl

The official docs describe NonlinearSolve as a unified nonlinear-solver interface with its own high-performance solvers and support for swapping direct or iterative linear solvers and sparse AD Jacobian paths. That makes it an excellent candidate once ASTRA has a real Newton/Henyey residual to solve.  
Source: [NonlinearSolve stable docs](https://docs.sciml.ai/NonlinearSolve/stable/).

### LinearSolve.jl

LinearSolve is positioned as a high-performance unified interface for Julia's linear-solver ecosystem, including operator-style problems, caching, and algorithm swapping. ASTRA should likely adopt it as the outer abstraction once the Jacobian and matrix structure become more serious.  
Source: [LinearSolve stable docs](https://docs.sciml.ai/LinearSolve/stable/).

### SparseDiffTools.jl

SparseDiffTools is explicitly about exploiting sparsity in Jacobians and Hessians, with coloring and matrix-free Jacobian-vector products. ASTRA should bring it in once sparsity becomes part of the real Jacobian story, not before.  
Source: [SparseDiffTools docs](https://docs.sciml.ai/SparseDiffTools/dev/).

### OrdinaryDiffEq.jl

OrdinaryDiffEq is the core ODE/DAE solver package in the SciML ecosystem. It is a strong future dependency for ASTRA once evolution becomes a serious target, but ASTRA should not let ODE tooling dictate its initial structure-solver design.  
Source: [OrdinaryDiffEq docs](https://docs.sciml.ai/OrdinaryDiffEq/dev/).

### SciMLSensitivity.jl

SciMLSensitivity is SciML's sensitivity-analysis and adjoint package. Its docs now explicitly cover nonlinear problems as part of the SciML common interface, which makes it promising later for solver sensitivities, calibration, and ASTRA-Stellax comparison work.  
Source: [SciMLSensitivity stable docs](https://docs.sciml.ai/SciMLSensitivity/stable/).

## Avoid for now

These are useful packages, but ASTRA should not let them drive bootstrap-stage architecture.

### PkgTemplates.jl

PkgTemplates is excellent for creating new Julia packages in an easy, repeatable, and customizable way. ASTRA already has its initial scaffold, so this is now a reference tool for future subpackages or related repos, not an immediate dependency to add to ASTRA itself.  
Source: [PkgTemplates stable docs](https://juliaci.github.io/PkgTemplates.jl/stable/).

### ComponentArrays.jl

ComponentArrays provides named indexing into flat arrays and is designed to compose nicely with solver workflows. That may become attractive later, but ASTRA should first stabilize its own explicit stellar-state types and pack/unpack logic.  
Source: [ComponentArrays docs](https://docs.sciml.ai/ComponentArrays/).

### ModelingToolkit.jl

ModelingToolkit is a symbolic-numeric modeling system with automatic transformations such as index reduction and model simplification. It is powerful, but it also risks becoming architecture-driving too early. ASTRA should first hand-own its equations, residuals, and state layout.  
Source: [ModelingToolkit docs](https://docs.sciml.ai/ModelingToolkit/dev/).

### Documenter.jl as the main site

Documenter is explicitly "a documentation generator for Julia" built from docstrings and markdown. It is absolutely worth knowing, and may become useful later for API reference pages, doctests, and docstring coverage. But ASTRA's main pedagogy-facing and planning-facing site should remain MystMD for now.  
Source: [Documenter.jl docs](https://documenter.juliadocs.org/stable/).

### GPU-first design

JuliaGPU's own docs say the CUDA stack is the most mature and full-featured GPU path in Julia. That is useful to know, but ASTRA should still treat correct serial CPU code as the primary design target until the classical forward solver is trustworthy.  
Source: [JuliaGPU Learn](https://juliagpu.org/learn/index.html) and [JuliaGPU CUDA overview](https://juliagpu.org/backends/cuda/).

## ASTRA's immediate package recommendation

If we were ranking ASTRA's next package moves right now, the order would be:

1. `Revise`
2. `Aqua`
3. `JET`
4. `BenchmarkTools`
5. `ForwardDiff`
6. `FiniteDiff`
7. later, once the solver is real: `NonlinearSolve`, `LinearSolve`, `SparseDiffTools`

That ranking is intentionally conservative. It buys quality-of-life and quality-assurance first, then derivative validation, and only later general solver infrastructure.

## Next design conversations

This dependency plan is not the architecture. It is a constraint on the architecture. The next ASTRA discussions should make four things explicit:

1. **contracts**: what the canonical state, residual, and formulation interfaces promise,
2. **testing and validation**: what qualifies as scaffold tests, physics tests, and later reference benchmarks,
3. **plotting**: what ASTRA should use for developer diagnostics and publication-quality figures,
4. **microphysics and data**: what ASTRA should implement internally versus wrap from external data tables and packages.

Those questions should be answered before ASTRA expands its dependency graph too aggressively.
