@testset "transport sign contract" begin
    problem = ASTRA.build_toy_problem(n_cells = 8)
    model = ASTRA.initialize_state(problem)
    n = problem.grid.n_cells

    interior = ASTRA.transport_row_terms(problem, model, 2)
    @test interior.delta_log_pressure < 0.0
    @test interior.nabla_transport > 0.0
    @test interior.gradient_term ≈ interior.nabla_transport * interior.delta_log_pressure
    @test interior.residual ≈ interior.delta_log_temperature - interior.gradient_term

    outer = ASTRA.transport_row_terms(problem, model, n - 1)
    @test outer.delta_log_pressure < 0.0
    @test outer.nabla_transport > 0.0
    @test outer.gradient_term ≈ outer.nabla_transport * outer.delta_log_pressure
    @test outer.residual ≈ outer.delta_log_temperature - outer.gradient_term
end
