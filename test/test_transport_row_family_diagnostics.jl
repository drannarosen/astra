@testset "transport row family diagnostics" begin
    problem = ASTRA.build_toy_problem(n_cells = 8)
    model = ASTRA.initialize_state(problem)
    residual = ASTRA.assemble_structure_residual(problem, model)
    summary = ASTRA.Solvers.row_family_merit_summary(problem, model, residual)

    @test summary.transport ≈ summary.interior_transport + summary.outer_transport
    @test summary.total ≈
          summary.center +
          summary.geometry +
          summary.hydrostatic +
          summary.luminosity +
          summary.transport +
          summary.surface
    @test summary.dominant_family in (
        :center,
        :geometry,
        :hydrostatic,
        :luminosity,
        :interior_transport,
        :outer_transport,
        :surface,
    )
end
