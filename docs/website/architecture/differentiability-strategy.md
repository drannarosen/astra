# Differentiability Strategy

ASTRA's differentiability story is built around one central idea: a stellar model is not a saved transcript of Newton iterations. It is the converged solution of a constrained physical system. That distinction matters because ASTRA wants derivatives of the solved physics, not derivatives of every temporary numerical detour taken along the way.

## What differentiable should mean in ASTRA

For the classical baseline, ASTRA solves a nonlinear system

$$
R(U; p) = 0,
$$

where `U` is the solve-owned structure state and `p` collects the inputs: physical parameters, controls, composition, grid choices, and closure settings.

The right differentiability question is therefore not "how do the Newton iterates change?" It is "how does the converged solution change?" That map from inputs `p` to solved state `U^\ast(p)` is the **solution map**, and it is the derivative boundary ASTRA should care about.

## The three ASTRA contracts

ASTRA needs three contracts to stay separate.

The **physics contract** says what equations the star satisfies and which layer owns each quantity. The **solve contract** says how ASTRA finds a state that approximately satisfies those equations. The **derivative contract** says what sensitivity object ASTRA means when it claims a solve is differentiable.

Keeping those contracts separate matters. Otherwise it becomes too easy to confuse "the equations," "the current nonlinear algorithm," and "the gradient definition" as if they were the same thing.

## The implicit-function-theorem view

Suppose ASTRA has solved

$$
R(U^\ast; p) = 0.
$$

Differentiate both sides with respect to `p`:

$$
\frac{\partial R}{\partial U}\frac{dU^\ast}{dp}
+
\frac{\partial R}{\partial p}
= 0.
$$

Rearranging gives

$$
\frac{dU^\ast}{dp}
=
-\left(\frac{\partial R}{\partial U}\right)^{-1}
\frac{\partial R}{\partial p}.
$$

This is the clean target for ASTRA's classical differentiability story. In plain language, ASTRA should differentiate the solved equations themselves.

For a scalar objective `\mathcal{L}(U^\ast(p), p)`, the reverse-mode form introduces an **adjoint** variable `\lambda`. The adjoint is just the helper variable that turns one large sensitivity problem into one linear solve against the transpose Jacobian:

$$
\left(\frac{\partial R}{\partial U}\right)^\top \lambda
=
\left(\frac{\partial \mathcal{L}}{\partial U^\ast}\right)^\top.
$$

Then

$$
\frac{d\mathcal{L}}{dp}
=
\frac{\partial \mathcal{L}}{\partial p}
-
\lambda^\top \frac{\partial R}{\partial p}.
$$

## Why ASTRA should not differentiate through Newton history

Tracing the full nonlinear iteration is tempting because it sounds automatic. For ASTRA, it is usually the wrong abstraction.

Those gradients would depend too strongly on damping decisions, fallback logic, saved intermediates, and other implementation details that are not the scientific object of interest. The Newton transcript still matters for diagnostics and debugging. It just should not be ASTRA's primary derivative object.

## Layer-by-layer strategy

Local microphysics kernels are good places for small, testable derivative work such as EOS or opacity derivatives. The global residual operator should remain physics-first and readable as an equation system. The nonlinear solve should be the first explicit derivative boundary, because `solve_structure(problem; state = guess)` is already ASTRA's public solve interface.

Only after the classical solve is trustworthy should ASTRA move outward to trajectory-level sensitivities through repeated constrained solves. That later problem is real, but it is not the first one.

ASTRA should stay backend-agnostic about which AD engine evaluates these derivatives. The architectural commitment is the derivative boundary and its meaning, not one permanently blessed backend.

## Why the classical lane comes first

The classical Henyey lane should own ASTRA's first serious differentiability surface because it gives the project an interpretable residual, an interpretable Jacobian, a clear solve-owned state, and a reference lane against which later formulations can be judged.

Entropy-DAE should therefore arrive later as a sibling formulation over the same operator core, not as a shortcut around unresolved baseline questions.

## Differentiability checklist

- [x] The page defines ASTRA's derivative target as the solution map, not the Newton transcript.
- [x] The physics, solve, and derivative contracts are separated clearly.
- [x] The implicit-differentiation equations are paired with plain-language meaning.
- [x] The public `solve_structure(problem; state = guess)` boundary is named as the natural derivative boundary.
- [x] The classical lane is identified as the first trustworthy differentiability target.
