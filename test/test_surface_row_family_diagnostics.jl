@testset "surface row family diagnostics" begin
    problem = ASTRA.build_toy_problem(n_cells = 12)
    model = ASTRA.initialize_state(problem)
    residual = ASTRA.assemble_structure_residual(problem, model)
    summary = ASTRA.Solvers.row_family_merit_summary(problem, model, residual)

    @test summary.surface ≈
          summary.surface_radius +
          summary.surface_luminosity +
          summary.surface_temperature +
          summary.surface_pressure
    @test summary.dominant_surface_family in (
        :surface_radius,
        :surface_luminosity,
        :surface_temperature,
        :surface_pressure,
    )
    @test summary.total ≈
          summary.center +
          summary.geometry +
          summary.hydrostatic +
          summary.luminosity +
          summary.transport +
          summary.surface
end
