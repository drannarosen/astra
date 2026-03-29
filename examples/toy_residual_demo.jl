using ASTRA

problem = ASTRA.build_toy_problem(n_cells = 10)
model = initialize_state(problem)
packed = ASTRA.pack_state(model.structure)
packed[1] += 1.0e-3
trial_structure = ASTRA.unpack_state(model.structure, packed)
trial_model = ASTRA.StellarModel(trial_structure, model.composition, model.evolution)

residual = ASTRA.assemble_structure_residual(problem, trial_model)
jacobian = ASTRA.finite_difference_jacobian(problem, trial_model)

println("Residual length: ", length(residual))
println("Residual norm: ", ASTRA.residual_norm(residual))
println("Jacobian size: ", size(jacobian))
