@testset "jacobian scaffold" begin
    problem = ASTRA.build_toy_problem(n_cells = 6)
    state = initialize_state(problem)
    jacobian = ASTRA.finite_difference_jacobian(problem, state)

    @test size(jacobian) == (length(ASTRA.pack_state(state)), length(ASTRA.pack_state(state)))
    @test all(isfinite, jacobian)
end
