# Solver Architecture

ASTRA's current classical solver stack is intentionally modest but now physically meaningful:

- the residual carries the first classical structure rows rather than an analytic reference-profile comparison,
- the Jacobian is still finite-difference,
- the nonlinear loop is still a plain Newton-style iteration,
- and convergence is tracked explicitly in diagnostics rather than hidden behind optimistic success language.

This is still not a research-grade stellar-structure solver. It is the first truthful surface where ASTRA can stabilize:

- state vector layout,
- residual ownership,
- Jacobian plumbing,
- nonlinear failure reporting,
- and developer workflows.

## Approved direction for the classical lane

The first serious classical residual should be organized around the ownership contract now documented in the architecture section:

- solve-owned structure block,
- evolution-owned timestep bookkeeping,
- microphysics-owned closures,
- diagnostics-owned derived reports.

The intended physical ordering of the residual is:

1. center boundary conditions,
2. interior structure equations cell by cell,
3. surface boundary conditions.

The intended state staggering is:

- face-centered `ln r` and `L`,
- cell-centered `ln T` and `ln rho`.

That staggering is not just a numerical detail. It is part of the canonical solver contract.

## Solver architecture versus differentiability

The next solver-architecture question is not "how do we backpropagate through every Newton iterate?" The better question is:

> what derivative object should ASTRA associate with a converged classical solve?

For ASTRA, the clean answer is the derivative of the **solution map** defined by the nonlinear system

$$  
R(U^\ast; p) = 0,
$$  

not the derivative of the full iteration history.

That is why the classical baseline should become trustworthy before ASTRA tries to make time evolution end-to-end differentiable. The solver boundary is where ASTRA should eventually place an explicit derivative contract, whether that is provided by ASTRA-owned ChainRules methods or by later SciML nonlinear-sensitivity tooling.
