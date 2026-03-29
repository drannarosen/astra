using ASTRA

problem = ASTRA.build_toy_problem(n_cells = 24)
result = solve_structure(problem)

println("Formulation: ", result.diagnostics.formulation)
println("Converged: ", result.diagnostics.converged)
println("Residual norm: ", result.diagnostics.residual_norm)
println("State summary: ", result.state)
