using ASTRA

problem = ASTRA.build_toy_problem(n_cells = 10)
state = initialize_state(problem)
packed = ASTRA.pack_state(state)
packed[1] += 1.0e-3
trial_state = ASTRA.unpack_state(state, packed)

residual = ASTRA.assemble_structure_residual(problem, trial_state)
jacobian = ASTRA.finite_difference_jacobian(problem, trial_state)

println("Residual length: ", length(residual))
println("Residual norm: ", ASTRA.residual_norm(residual))
println("Jacobian size: ", size(jacobian))
