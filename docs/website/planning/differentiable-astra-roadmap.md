# Differentiable ASTRA Roadmap

This page records ASTRA's recommended path toward end-to-end differentiability in Julia.

The guiding rule is:

> make the classical baseline trustworthy first, make its kernels AD-safe second, differentiate the solved system third, and only then promote time evolution to a richer differential-algebraic frontend.

That order is deliberate. It keeps ASTRA on a narrow falsifiable slice instead of asking one architectural leap to solve physics validation, nonlinear robustness, automatic differentiation, and formulation research all at once.

## Short answer

For ASTRA, "end-to-end differentiable" should eventually mean:

$$
\text{inputs and controls}
\longrightarrow
\text{local closures}
\longrightarrow
\text{converged structure solves}
\longrightarrow
\text{evolution trajectory}
\longrightarrow
\text{observables or loss}
\longrightarrow
\text{gradients}.
$$

It should not mean "record every Newton iteration and backpropagate through the full iteration transcript by default."

## Phase 1: classical Henyey baseline first

The first serious lane should remain the classical baseline.

The near-term goals are:

- trustworthy residual semantics,
- trustworthy boundary semantics,
- clear Jacobian structure,
- robust nonlinear diagnostics,
- and validation hooks that can survive later method expansion.

This phase is about scientific and architectural clarity. It is not yet about making every code path differentiable.

### What ASTRA should own in this phase

- state types and ownership contracts,
- residual and boundary semantics,
- pack/unpack discipline,
- Jacobian structure and linearization policy,
- convergence diagnostics,
- validation reports.

### What ASTRA should not overbuild yet

- full time-evolution sensitivities,
- a generalized DAE frontend,
- aggressive solver-package coupling,
- or backend-specific AD plumbing in every file.

## Phase 2: make local physics kernels AD-safe

Once the classical lane is scientifically legible, the next step is to make the local kernels safe targets for derivative tools.

That means ASTRA should check:

- EOS kernels,
- opacity kernels,
- nuclear-rate kernels,
- transport-coefficient kernels,
- and any local closure blends or switches.

For each kernel, ASTRA should ask:

1. is the function mostly pure,
2. are the inputs and outputs explicit,
3. do local derivatives agree with finite differences,
4. do any sharp switches need smoothing or explicit non-differentiable handling,
5. is a custom derivative rule actually needed here.

Current checkpoint:

- ASTRA now validates the local temperature sensitivity of the radiative-temperature-gradient helper against a finite-difference reference on the bootstrap classical lane.
- The current explicit derivative surface is still intentionally narrow: toy EOS and Kramers-opacity temperature derivatives plus a helper-level comparison test.
- This is enough to prove where local derivatives belong in the architecture, but it is not yet evidence for solver-boundary or trajectory-level sensitivities.

## Phase 3: define a derivative boundary for the structure solve

This is the decisive differentiability step.

ASTRA should wrap the converged structure solve as a mathematically meaningful function, conceptually something like

```julia
model_star = solve_structure(problem; state = guess)
```

and then define its derivative in terms of the converged residual system, not the Newton trace.

Current checkpoint:

- ASTRA now treats `solve_structure(problem; state = guess)` as the named public solve boundary for later sensitivity work.
- The current milestone is interface-level only: diagnostics and docs now say what that boundary owns, but no `rrule`, `frule`, or solver-aware sensitivity package integration has landed yet.

### Practical Julia tools

The Julia ecosystem now makes this feasible without forcing ASTRA into one backend forever.

ASTRA should view the relevant tools this way:

- `ForwardDiff`: local derivatives and small Jacobian blocks,
- `FiniteDiff`: derivative validation and debugging,
- `ChainRulesCore`: explicit `frule` / `rrule` definitions at solver boundaries,
- `ChainRulesTestUtils`: regression tests for those rules,
- SciML nonlinear sensitivity tooling: solver-aware implicit differentiation when ASTRA is ready to integrate more closely with that stack.

## Phase 4: expose trajectory-level gradients

Only after the structure solve has a trustworthy derivative contract should ASTRA promote trajectory-level gradients.

At that point the outer problem becomes:

- repeated structure solves,
- timestep control and acceptance logic,
- observable construction,
- and a scalar or vector objective.

This is where SciML's broader sensitivity stack becomes attractive. The key architectural rule does not change:

> the structure solve remains a derivative boundary with equation-level meaning.

That keeps the evolution layer from becoming an opaque chain of nested AD accidents.

## Phase 5: Entropy-DAE later

Entropy-DAE should remain a later frontend.

That is still the right call even in a differentiable-ASTRA discussion.

By the time ASTRA reaches this phase, the project should already own:

- a clean operator core,
- a validated classical reference lane,
- a solver interface with honest diagnostics,
- and an explicit derivative contract for nonlinear projections.

Then Entropy-DAE becomes an extension of the architecture rather than a replacement for it.

## Package guidance for this roadmap

ASTRA should keep the package strategy conservative.

### Use confidently

- `ForwardDiff` for local derivatives,
- `FiniteDiff` for derivative checks,
- `ChainRulesCore` for custom rule definitions,
- `ChainRulesTestUtils` for derivative-rule testing.

### Introduce when the solver interface is mature enough

- `NonlinearSolve` as a future nonlinear-solver frontend candidate,
- `LinearSolve` as a future outer linear-solver abstraction candidate,
- `SciMLSensitivity` when ASTRA is ready to exercise solver-aware sensitivities at the solve and trajectory levels.

### Keep backend choice flexible

ASTRA should avoid teaching a permanent commitment to "Zygote everywhere" or any single outer AD engine. The better long-term rule is:

- design backend-agnostic derivative contracts,
- keep boundary semantics explicit,
- and choose the VJP backend that matches the surrounding layer and maturity of the Julia ecosystem at that time.

## Is this design correct and innovative?

The short answer is:

- **correct in direction**: yes,
- **good for ASTRA specifically**: yes,
- **innovative in application and architecture**: yes,
- **novel as mathematics by itself**: no.

Implicit differentiation of nonlinear solves, custom derivative rules, and solver-aware sensitivity methods are established ideas. ASTRA's opportunity is to apply them with unusual architectural discipline in a stellar-evolution code:

- explicit ownership contracts,
- explicit residual semantics,
- explicit derivative boundaries,
- and a classical reference lane that remains scientifically readable.

That combination is where ASTRA can be genuinely distinctive.

## The main corrections to keep in mind

The broad proposal is strong, but ASTRA's docs should state a few refinements explicitly.

### Correction 1: backend-agnostic, not Zygote-first

Zygote is an important Julia tool and its limitations around mutation are real, but ASTRA's architectural recommendation should not be framed as though one AD backend owns the future of the project.

The stronger rule is:

> ASTRA owns the derivative contract. AD backends are replaceable infrastructure.

### Correction 2: do not oversell SciML adoption timing

`NonlinearSolve`, `LinearSolve`, and `SciMLSensitivity` are strong candidates for later phases, but ASTRA should still preserve its own operator and formulation ownership even if those packages are adopted.

### Correction 3: innovation should be described honestly

ASTRA should not claim to have invented implicit differentiation or solver adjoints. The honest claim is that ASTRA is designing a stellar-code architecture where those tools are first-class from the beginning instead of being bolted on after the solver becomes opaque.

`Insight ----------------------------------------`
- The most important planning choice is the order: classical baseline, AD-safe kernels, implicit solve boundary, trajectory sensitivities, then Entropy-DAE. If ASTRA breaks that order, later gradients will be harder to trust because the baseline physics and solver semantics will still be moving targets.
- A future contributor should be able to read this page and know exactly where a proposed AD package belongs: local kernels, solver boundary, or outer trajectory. If the answer is "everywhere," the proposal is not mature enough.
`------------------------------------------------`
