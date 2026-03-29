# Quickstart

The bootstrap quickstart is intentionally modest. It does **not** claim to solve a production stellar model. It shows how ASTRA's package architecture, state representation, toy residual path, and diagnostics fit together.

```julia
using ASTRA

problem = ASTRA.build_toy_problem(n_cells = 24)
result = solve_structure(problem)

println(result.diagnostics)
println(result.state)
```

## What this run means

In the current bootstrap, the residual system is an analytic reference-profile problem used to exercise:

- state packing and unpacking,
- boundary-condition ownership,
- finite-difference Jacobian construction,
- nonlinear iteration bookkeeping,
- and formulation dispatch.

That is useful because it lets ASTRA grow around a real numerical interface without pretending that the classical stellar-structure physics is already finished.
