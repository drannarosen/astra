using ASTRA

problem = ASTRA.build_toy_problem(n_cells = 24)
result = solve_structure(problem)

println("Formulation: ", result.diagnostics.formulation)
println("Converged: ", result.diagnostics.converged)
println("Iterations: ", result.diagnostics.iterations)
println("Initial residual norm: ", result.diagnostics.initial_residual_norm)
println("Final residual norm: ", result.diagnostics.residual_norm)
println("Accepted steps: ", result.diagnostics.accepted_step_count)
println("Rejected trials: ", result.diagnostics.rejected_trial_count)
println("Damping history: ", result.diagnostics.damping_history)
println("Cells: ", result.state.structure.grid.n_cells)
println("Outer radius [cm]: ", exp(result.state.structure.log_radius_face_cm[end]))
println("Surface hydrogen fraction: ", result.state.composition.hydrogen_mass_fraction_cell[end])
println("Model age [s]: ", result.state.evolution.age_s)
