# Quickstart

The bootstrap quickstart is intentionally modest. It does **not** claim to solve a production stellar model. It shows how ASTRA's package architecture, explicit model ownership, toy residual path, and diagnostics fit together.

```julia
using ASTRA

problem = ASTRA.build_toy_problem(n_cells = 24)
result = solve_structure(problem)

println(result.diagnostics)
println("Packed structure length: ", length(ASTRA.pack_state(result.state.structure)))
println("Surface X: ", result.state.composition.hydrogen_mass_fraction_cell[end])
println("Age [s]: ", result.state.evolution.age_s)
```

## What this run means

In the current bootstrap, the residual system is an analytic reference-profile problem used to exercise:

- structure-state packing and unpacking,
- boundary-condition ownership,
- finite-difference Jacobian construction,
- nonlinear iteration bookkeeping,
- and formulation dispatch.

The returned object is a `StellarModel` with explicit `structure`, `composition`, and `evolution` blocks. That is useful because it lets ASTRA grow around a real numerical interface without pretending that the classical stellar-structure physics is already finished.

## What to notice in the output

- `result.diagnostics` tells you what the current solve did and what formulation it used.
- `ASTRA.pack_state(result.state.structure)` shows the exact block that the bootstrap Newton solve owns.
- `result.state.composition` is persistent model state, but it is not part of the initial solve vector.
- `result.state.evolution` exists so timestep-aware ownership has a real home later instead of being hidden in ad hoc diagnostics.
