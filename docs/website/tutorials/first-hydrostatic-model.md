# First Hydrostatic Model

In the bootstrap repository, the phrase "first hydrostatic model" should be read carefully. The current code exercises the *shape* of a hydrostatic solve, not the full classical stellar-structure physics.

## First workflow

```julia
using ASTRA

problem = ASTRA.build_toy_problem(n_cells = 32)
result = solve_structure(problem)

println(result.state)
println(result.diagnostics)
```

## What to notice

- the package imports cleanly,
- the problem bundle is explicit,
- the state object has stable field ownership,
- the solver returns a diagnostics object instead of a raw vector.

Those are the first habits ASTRA wants to teach.
