@testset "jacobian scaffold" begin
    problem = ASTRA.build_toy_problem(n_cells = 6)
    model = initialize_state(problem)
    packed = ASTRA.pack_state(model.structure)
    jacobian = ASTRA.finite_difference_jacobian(problem, model)

    @test size(jacobian) == (length(packed), length(packed))
    @test all(isfinite, jacobian)
end
