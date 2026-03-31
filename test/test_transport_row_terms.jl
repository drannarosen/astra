@testset "transport row terms" begin
    problem = ASTRA.build_toy_problem(n_cells = 8)
    model = ASTRA.initialize_state(problem)
    n = problem.grid.n_cells

    interior = ASTRA.transport_row_terms(problem, model, 2)
    @test interior.location == :interior
    @test !interior.is_outer
    @test interior.residual ≈ interior.delta_log_temperature - interior.gradient_term
    @test interior.gradient_term ≈ interior.nabla_transport * interior.delta_log_pressure

    outer = ASTRA.transport_row_terms(problem, model, n - 1)
    @test outer.location == :outer
    @test outer.is_outer
    @test outer.residual ≈ outer.delta_log_temperature - outer.gradient_term
    @test outer.gradient_term ≈ outer.nabla_transport * outer.delta_log_pressure
    @test outer.transport_pressure_target_dyn_cm2 > 0.0
end
