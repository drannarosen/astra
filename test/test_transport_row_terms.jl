@testset "transport row terms" begin
    problem = ASTRA.build_toy_problem(n_cells = 8)
    model = ASTRA.initialize_state(problem)
    n = problem.grid.n_cells

    interior = ASTRA.transport_row_terms(problem, model, 2)
    interior_state = ASTRA.cell_transport_state(problem, model, 2)
    @test interior.location == :interior
    @test !interior.is_outer
    @test interior.residual ≈ interior.delta_log_temperature - interior.gradient_term
    @test interior.gradient_term ≈ interior.nabla_transport * interior.delta_log_pressure
    @test interior.nabla_transport ≈ interior_state.active_gradient
    @test interior.nabla_radiative ≈ interior_state.radiative_gradient
    @test interior.nabla_ledoux ≈ interior_state.ledoux_gradient
    @test interior.gradient_term ≈ interior.nabla_transport * interior.delta_log_pressure

    outer = ASTRA.transport_row_terms(problem, model, n - 1)
    outer_state = ASTRA.cell_transport_state(problem, model, n - 1)
    @test outer.location == :outer
    @test outer.is_outer
    @test outer.residual ≈ outer.delta_log_temperature - outer.gradient_term
    @test outer.gradient_term ≈ outer.nabla_transport * outer.delta_log_pressure
    @test outer.nabla_transport ≈ outer_state.active_gradient
    @test outer.transport_regime == outer_state.transport_regime
    @test outer.transport_pressure_target_dyn_cm2 > 0.0
end
