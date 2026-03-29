# Differentiability Strategy

ASTRA's differentiability story should be built around one central idea:

> a stellar model is not a recorded sequence of Newton iterates. It is the converged solution of a constrained physical system.

That distinction matters. If ASTRA tries to become "end-to-end differentiable" by naively tracing every nonlinear iteration, every damping decision, and every temporary solver allocation, the gradients will depend too strongly on implementation detail. For ASTRA, the scientifically meaningful object is the **solution map**, not the iteration history.

## What differentiable should mean in ASTRA

For the classical baseline, ASTRA solves a nonlinear system

$$
R(U; p) = 0,
$$

where:

- $U$ is the solve-owned structure state,
- $p$ collects physical parameters, controls, composition inputs, grid controls, and closure parameters,
- and $R$ is the discretized stellar-structure residual.

In the current ownership contract, that state is carried by `model.structure`, while composition and timestep-aware metadata remain attached to the full `StellarModel`.

The differentiable question is therefore not

$$
\text{How do the Newton iterates } U_0, U_1, U_2, \ldots \text{ change with } p?
$$

but rather

$$  
\text{How does the converged solution } U^\ast(p) \text{ change with } p?
$$  

That is the right mathematical boundary for ASTRA.

## The three ASTRA contracts

ASTRA should make three contracts explicit.

### Physics contract

The physics contract says what equations the star satisfies and which layer owns each quantity.

For the classical lane, the operator layer should own:

1. center boundary rows,
2. interior geometry rows,
3. hydrostatic rows,
4. luminosity or energy rows,
5. transport rows,
6. surface boundary rows.

Microphysics should provide closures and coefficients. It should not quietly take ownership of the global residual semantics.

### Solve contract

The solve contract says how ASTRA obtains a state satisfying the equations.

For the classical Henyey baseline, that means Newton-like iteration on the solve-owned structure block:

$$
J(U_k; p)\,\Delta U_k = -R(U_k; p),
$$

followed by an update of the form

$$
U_{k+1} = U_k + \lambda_k \Delta U_k.
$$

The exact damping policy, linear solver, or Jacobian construction can evolve later, but the contract should remain that the solver returns a state that approximately satisfies the operator equations.

### Derivative contract

The derivative contract says how sensitivities of the solved state are defined.

This is the contract that many scientific codes leave implicit. ASTRA should not.

The correct derivative object for the converged structure solve is the derivative of the solution map $U^\ast(p)$, not the derivative of the Newton transcript.

## The implicit-function-theorem view

Suppose ASTRA has solved

$$  
R(U^\ast; p) = 0.
$$  

Differentiate both sides with respect to a parameter vector $p$:

$$  
\frac{\partial R}{\partial U}\frac{dU^\ast}{dp}
+
\frac{\partial R}{\partial p}
= 0.
$$  

Rearranging gives the forward sensitivity formula

$$  
\frac{dU^\ast}{dp}
=
-\left(\frac{\partial R}{\partial U}\right)^{-1}
\frac{\partial R}{\partial p}.
$$  

This is the mathematically clean differentiability target for ASTRA's classical solve.

For reverse-mode work, suppose a scalar objective $\mathcal{L}(U^\ast(p), p)$ depends on the solved state. Introduce an adjoint variable $\lambda$ satisfying

$$  
\left(\frac{\partial R}{\partial U}\right)^\top \lambda
=
\left(\frac{\partial \mathcal{L}}{\partial U^\ast}\right)^\top.
$$  

Then the total parameter gradient becomes

$$
\frac{d\mathcal{L}}{dp}
=
\frac{\partial \mathcal{L}}{\partial p}
-
\lambda^\top \frac{\partial R}{\partial p}.
$$

That formula is what ASTRA should mean by differentiating a converged structure solve.

## Why ASTRA should not differentiate through Newton history

Tracing the full nonlinear iteration is tempting because it sounds automatic. For ASTRA, it is usually the wrong abstraction.

The disadvantages are significant:

- gradients become sensitive to line-search and damping details,
- the reverse pass inherits every temporary mutation and branch in the solver host code,
- memory use grows with saved iteration history,
- and the derivative contract becomes harder to explain scientifically.

The implicit-differentiation approach keeps the gradient tied to the actual equation system rather than to the temporary numerical path used to solve it.

That does not mean Newton history is useless. The iteration transcript is still valuable for diagnostics, convergence studies, and debugging. It just should not be ASTRA's primary derivative object.

## Layer-by-layer AD strategy

ASTRA should not force one automatic-differentiation mode on the whole stack. The Julia ecosystem is strongest when the method is matched to the layer.

### Local microphysics kernels

These are good candidates for small-scope derivative tools:

- EOS thermodynamic derivatives,
- opacity derivatives,
- source-term derivatives,
- transport-coefficient derivatives.

For ASTRA, the design goal here is simple:

- prefer pure functions,
- keep inputs and outputs explicit,
- make local derivatives testable against finite differences,
- and add custom rules only when a closure is awkward for generic AD.

### Global operator layer

The operator layer assembles the full stellar residual. It should remain physics-first:

- boundary-condition semantics,
- equation ordering,
- grid geometry,
- zone coupling,
- and residual meaning all belong here.

This layer should be differentiable, but it should not be written as though reverse-mode AD will magically replace operator design.

### Solver boundary

The nonlinear solve should be the first explicit derivative boundary in ASTRA.

That boundary is where ASTRA should use either:

- solver-aware nonlinear sensitivities from the SciML stack, or
- an ASTRA-owned `rrule` / `frule` for a wrapped solve function.

In both cases, the meaning is the same: differentiate the solved system implicitly.

### Evolution layer

Only after the classical solve is trustworthy should ASTRA expose trajectory-level gradients through repeated constrained solves.

At that point the outer sensitivity problem becomes a different question:

$$
p \longrightarrow \text{trajectory} \longrightarrow \text{observables} \longrightarrow \mathcal{L}.
$$

That outer layer may use adjoint or forward sensitivity methods appropriate to the time-integration problem, but it should still treat the structure solve as a mathematically explicit projection or solve boundary.

## Backend-agnostic does not mean boundary-free

ASTRA should be backend-agnostic about which AD engine performs vector-Jacobian products:

- `ForwardDiff` is a strong fit for local derivative blocks,
- `ChainRulesCore` is the right place to define explicit derivative rules,
- `ChainRulesTestUtils` is the right place to test them,
- and SciML sensitivity tooling can select among multiple VJP backends for outer sensitivity calculations.

The key architectural point is not "pick one blessed AD package forever." The key point is:

> put explicit derivative boundaries at the physically meaningful interfaces.

That keeps ASTRA scientifically legible even if the preferred backend changes later.

## Why the classical Henyey lane should come first

The current ASTRA formulation policy already says that `ClassicalHenyeyFormulation` is the canonical lane and `EntropyDAEFormulation` is intentionally downstream.

That is also the right differentiability order.

The classical baseline gives ASTRA:

- a trustworthy residual operator,
- an interpretable Jacobian,
- a clear solve-owned state,
- a natural location for implicit differentiation,
- and a reference lane against which later formulations can be judged.

If ASTRA skips that step and tries to make the first differentiable story be an Entropy-DAE workflow, the code risks mixing formulation experimentation with unresolved baseline-solver questions.

## What changes later for Entropy-DAE

Entropy-DAE should be treated as a later frontend over the same operator core, not as a separate codebase.

Conceptually, ASTRA would split the state into:

- differential variables $y$,
- algebraic variables $z$,

with a constraint system

$$
g(t, y, z; p) = 0.
$$

At each step, the time integrator advances or predicts the differential state, and ASTRA then solves the algebraic projection problem for $z$.

That is still a nonlinear solve. The same derivative discipline applies:

- local kernels remain differentiable,
- the projection solve remains an implicit derivative boundary,
- and the outer trajectory sensitivities are handled with solver-aware sensitivity methods rather than with naive tape-through-everything logic.

## Current ASTRA status versus future differentiable target

ASTRA is not yet at the stage where full differentiable stellar evolution should be advertised. What is true today is narrower and more useful:

- the repo now has an explicit ownership model,
- the classical residual is real rather than pedagogical,
- the Jacobian and diagnostics are honest about that residual,
- and the documentation can now state the differentiability architecture without pretending the whole pipeline is already implemented.

That is the right level of truthfulness for this stage.

`Insight ----------------------------------------`
- The innovative part for ASTRA is not the bare existence of implicit differentiation. That mathematics is established. The innovation is making the derivative contract a first-class architectural object in a stellar code whose baseline lane is still solver-transparent and validation-driven.
- Future edits should preserve the separation between operator meaning and solver implementation. If a proposed AD change blurs that boundary, it is usually architectural debt, not progress.
`------------------------------------------------`
