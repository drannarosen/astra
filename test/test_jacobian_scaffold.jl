@testset "jacobian scaffold" begin
    problem = ASTRA.build_toy_problem(n_cells = 6)
    model = initialize_state(problem)
    jacobian = ASTRA.finite_difference_jacobian(problem, model)

    @test size(jacobian) == (
        length(ASTRA.pack_state(model.structure)),
        length(ASTRA.pack_state(model.structure)),
    )
    @test all(isfinite, jacobian)
    @test any(!iszero, jacobian)
end
