@testset "transport row weights" begin
    problem = ASTRA.build_toy_problem(n_cells = 8)
    model = ASTRA.initialize_state(problem)
    weights = ASTRA.Solvers.residual_row_weights(problem, model)
    n = problem.grid.n_cells

    interior_row = first(ASTRA.interior_structure_row_range(1)) + 3
    interior = ASTRA.transport_row_terms(problem, model, 1)
    expected_interior_weight = 1.0 / max(
        abs(interior.delta_log_temperature),
        abs(interior.gradient_term),
        1.0,
    )

    outer_k = n - 1
    outer_row = first(ASTRA.interior_structure_row_range(outer_k)) + 3
    outer = ASTRA.transport_row_terms(problem, model, outer_k)
    expected_outer_weight = 1.0 / max(
        abs(outer.delta_log_temperature),
        abs(outer.gradient_term),
        1.0,
    )

    @test weights[interior_row] ≈ expected_interior_weight
    @test weights[outer_row] ≈ expected_outer_weight
end
