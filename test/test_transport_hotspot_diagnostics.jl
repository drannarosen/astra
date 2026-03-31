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
    @test hotspot.transport_regime in (:radiative, :convective)
    @test isfinite(hotspot.nabla_radiative)
    @test isfinite(hotspot.nabla_ledoux)
    @test isfinite(hotspot.nabla_transport)
    @test isfinite(hotspot.superadiabatic_excess)
    @test hotspot.superadiabatic_excess ≈ hotspot.nabla_transport - hotspot.nabla_ledoux
    @test 0.0 <= hotspot.convective_flux_fraction <= 1.0
    @test hotspot.convective_velocity_cm_s >= 0.0
    @test hotspot.weighted_contribution ≈ hotspot.row_weight * hotspot.raw_residual
    @test hotspot.raw_residual ≈ hotspot.delta_log_temperature - hotspot.gradient_term
    @test hotspot.gradient_term ≈ hotspot.nabla_transport * hotspot.delta_log_pressure
    if hotspot.transport_regime == :radiative
        @test hotspot.convective_velocity_cm_s == 0.0
        @test hotspot.convective_flux_fraction == 0.0
    end
end
