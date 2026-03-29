using ASTRA

problem = ASTRA.build_toy_problem(n_cells = 64)
state = initialize_state(problem)

residual_time = @elapsed ASTRA.assemble_structure_residual(problem, state)
jacobian_time = @elapsed ASTRA.finite_difference_jacobian(problem, state)
solve_time = @elapsed solve_structure(problem)

println("Residual assembly time [s]: ", residual_time)
println("Jacobian assembly time [s]: ", jacobian_time)
println("Toy solve time [s]: ", solve_time)
