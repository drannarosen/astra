@testset "residual scaffold" begin
    problem = ASTRA.build_toy_problem(n_cells = 8)
    state = initialize_state(problem)
    residual = ASTRA.assemble_structure_residual(problem, state)

    @test length(residual) == length(ASTRA.pack_state(state))
    @test all(isfinite, residual)
end
