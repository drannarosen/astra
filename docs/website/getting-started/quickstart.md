# Quickstart

This quickstart is intentionally modest. It does **not** produce a production stellar model. Instead, you will build a small ASTRA test problem, run the current classical structure solve, and inspect the main pieces ASTRA exposes: the problem setup, the solved model state, and the diagnostics that describe what the solver did.

## Run the example

Start Julia from the repository root:

```bash
julia --project=.
```

Paste and run the following code:

```julia
using ASTRA

# Build a small toy stellar model problem
problem = ASTRA.build_toy_problem(n_cells = 24)

# Run the classical structure solve
result = solve_structure(problem)

# Inspect diagnostics
println(result.diagnostics)

# Inspect structure vector size
println("Packed structure length: ", length(ASTRA.pack_state(result.state.structure)))

# Inspect surface composition
println("Surface X: ", result.state.composition.hydrogen_mass_fraction_cell[end])

# Inspect model age
println("Age [s]: ", result.state.evolution.age_s)
```

## What you just ran

`problem` is a small test star model. It contains the ingredients ASTRA needs to define the current calculation: a mesh, parameters, microphysics closures, and solver settings.

`solve_structure(problem)` tries to solve the current stellar structure equations for that problem. Here, a **solve** means "adjust the model until the equations and boundary conditions are satisfied as well as the current method allows."

`result` is the returned model object. Here, an **object** is just a Julia value that groups related information together. It contains the current model **state** and the **diagnostics**. A state is the stored physical information for the model. Diagnostics are the measurements and notes that explain what happened during the run.

## What this run means

In the current bootstrap, this example exercises several important parts of ASTRA:

- packing the structure state (turning the structure model into a vector for the solver),
- unpacking the structure state (turning that vector back into named model fields),
- boundary-condition ownership (which part of the code enforces the center and surface conditions),
- block-aware Jacobian assembly (building derivative information in organized row and column blocks),
- a dense finite-difference reference path (a simpler derivative check used as a comparison surface),
- nonlinear iteration bookkeeping (tracking repeated solver steps, rejected trials, and residual history),
- and formulation dispatch (choosing which formulation implementation the solve uses).

The returned object is a `StellarModel` with explicit `structure`, `composition`, and `evolution` blocks. This separation is architectural, not cosmetic. It is part of the `ASTRA` package architecture, not just a convenience for this example.

The public solve boundary is `solve_structure(problem; state = guess)`. Only `result.state.structure` is **solve-owned**, meaning it is the part the current Newton solve is allowed to update directly. Composition and evolution remain persistent model state. In plain language: the solver is solving for structure, while composition and age-related information stay attached to the model without being part of the current solve vector.

## What to notice in the output

Focus on these first:

- `result.diagnostics` shows what the solver did, which formulation it used, and how far the run progressed.
- `ASTRA.pack_state(result.state.structure)` shows the exact structure block that ASTRA turns into a vector for the solve.
- `result.state.composition` stores the model composition. It is real model state, but it is not part of the current solve vector.
- `result.state.evolution` stores time-dependent quantities such as age. That gives later evolution work a real home instead of hiding it in diagnostics.
- The example reports its convergence status honestly. Right now the bootstrap classical solve is still non-converged on the toy examples. Here, **non-converged** means the solver has not yet reached a physical solution, which is expected at this stage.
