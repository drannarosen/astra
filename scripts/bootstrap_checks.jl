using ASTRA

problem = ASTRA.build_toy_problem()
state = initialize_state(problem)
residual = ASTRA.assemble_structure_residual(problem, state)
result = solve_structure(problem)

println("Bootstrap checks")
println("  cells: ", problem.grid.n_cells)
println("  packed-state length: ", length(ASTRA.pack_state(state)))
println("  residual norm: ", ASTRA.residual_norm(residual))
println("  converged: ", result.diagnostics.converged)
