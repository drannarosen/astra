using ASTRA

problem = ASTRA.build_toy_problem(n_cells = 24)
result = solve_structure(problem)

println("Formulation: ", result.diagnostics.formulation)
println("Converged: ", result.diagnostics.converged)
println("Residual norm: ", result.diagnostics.residual_norm)
println("Cells: ", result.state.structure.grid.n_cells)
println("Outer radius [cm]: ", exp(result.state.structure.log_radius_face_cm[end]))
println("Surface hydrogen fraction: ", result.state.composition.hydrogen_mass_fraction_cell[end])
println("Model age [s]: ", result.state.evolution.age_s)
