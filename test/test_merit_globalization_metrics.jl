@testset "merit globalization metrics" begin
    problem = ASTRA.build_toy_problem(n_cells = 8)
    model = initialize_state(problem)
    residual = ASTRA.assemble_structure_residual(problem, model)
    row_weights = ASTRA.Solvers.residual_row_weights(problem, model)

    merit = ASTRA.Solvers.weighted_residual_merit(residual, row_weights)
    problem_merit = ASTRA.Solvers.weighted_residual_merit(problem, model, residual)
    weighted_norm = ASTRA.Solvers.weighted_residual_norm(residual, row_weights)
    summary = ASTRA.Solvers.row_family_merit_summary(
        problem,
        model,
        residual;
        row_weights = row_weights,
    )

    @test merit ≈ 0.5 * length(residual) * weighted_norm^2 rtol = 1e-12
    @test problem_merit ≈ merit rtol = 1e-12
    @test summary.total ≈ merit rtol = 1e-12
    @test summary.center + summary.geometry + summary.hydrostatic + summary.luminosity +
          summary.transport + summary.surface ≈ summary.total rtol = 1e-12
    @test summary.surface ≈
          summary.surface_radius +
          summary.surface_luminosity +
          summary.surface_temperature +
          summary.surface_pressure rtol = 1e-12
    @test summary.center >= 0.0
    @test summary.geometry >= 0.0
    @test summary.hydrostatic >= 0.0
    @test summary.luminosity >= 0.0
    @test summary.interior_transport >= 0.0
    @test summary.outer_transport >= 0.0
    @test summary.transport >= 0.0
    @test summary.surface >= 0.0
    @test summary.dominant_family in (
        :center,
        :geometry,
        :hydrostatic,
        :luminosity,
        :interior_transport,
        :outer_transport,
        :surface,
    )
    @test summary.dominant_surface_family in (
        :surface_radius,
        :surface_luminosity,
        :surface_temperature,
        :surface_pressure,
    )
end
