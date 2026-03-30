@testset "transport row family diagnostics" begin
    problem = ASTRA.build_toy_problem(n_cells = 8)
    model = ASTRA.initialize_state(problem)
    residual = ASTRA.assemble_structure_residual(problem, model)
    summary = ASTRA.Solvers.row_family_merit_summary(problem, model, residual)
    row_weights = ASTRA.Solvers.residual_row_weights(problem, model)
    n = problem.grid.n_cells
    interior_transport_row = first(ASTRA.interior_structure_row_range(1)) + 3
    outer_transport_row = first(ASTRA.interior_structure_row_range(n - 1)) + 3

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
    @test row_weights[interior_transport_row] == 1.0
    @test row_weights[outer_transport_row] == 1.0
end
