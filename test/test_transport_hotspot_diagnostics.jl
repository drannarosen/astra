@testset "transport hotspot diagnostics" begin
    problem = ASTRA.build_toy_problem(n_cells = 8)
    model = ASTRA.initialize_state(problem)
    residual = ASTRA.assemble_structure_residual(problem, model)
    weights = ASTRA.Solvers.residual_row_weights(problem, model)

    hotspot = ASTRA.Solvers.transport_hotspot_summary(
        problem,
        model,
        residual;
        row_weights = weights,
    )

    @test hotspot.present
    @test hotspot.cell_index in 1:(problem.grid.n_cells - 1)
    @test hotspot.location in (:interior, :outer)
    @test hotspot.weighted_contribution ≈ hotspot.row_weight * hotspot.raw_residual
    @test hotspot.raw_residual ≈ hotspot.delta_log_temperature - hotspot.gradient_term
    @test hotspot.gradient_term ≈ hotspot.nabla_transport * hotspot.delta_log_pressure
end
