using ASTRA

problem = ASTRA.build_toy_problem()
model = initialize_state(problem)
model isa ASTRA.StellarModel || error("initialize_state(problem) must return StellarModel.")
residual = ASTRA.assemble_structure_residual(problem, model)
result = solve_structure(problem)

println("Bootstrap checks")
println("  cells: ", problem.grid.n_cells)
println("  packed-state length: ", length(ASTRA.pack_state(model.structure)))
println("  residual norm: ", ASTRA.residual_norm(residual))
println("  converged: ", result.diagnostics.converged)
