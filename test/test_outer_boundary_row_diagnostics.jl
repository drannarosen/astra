@testset "outer boundary row diagnostics" begin
    problem = ASTRA.build_toy_problem(n_cells = 12)
    model = ASTRA.initialize_state(problem)
    residual = ASTRA.assemble_structure_residual(problem, model)
    weights = ASTRA.Solvers.residual_row_weights(problem, model)

    summary = ASTRA.Solvers.outer_boundary_row_summary(
        problem,
        model,
        residual;
        row_weights = weights,
    )

    n = problem.grid.n_cells
    surface_rows = ASTRA.structure_surface_row_range(n)
    outer_transport_row = first(ASTRA.interior_structure_row_range(n - 1)) + 3

    @test summary.present
    @test summary.outer_transport_row_index == outer_transport_row
    @test summary.surface_temperature_row_index == surface_rows[3]
    @test summary.surface_pressure_row_index == surface_rows[4]
    @test summary.outer_transport_raw ≈ residual[outer_transport_row]
    @test summary.surface_temperature_raw ≈ residual[surface_rows[3]]
    @test summary.surface_pressure_raw ≈ residual[surface_rows[4]]
    @test summary.outer_transport_weighted ≈ weights[outer_transport_row] * residual[outer_transport_row]
    @test summary.surface_temperature_weighted ≈ weights[surface_rows[3]] * residual[surface_rows[3]]
    @test summary.surface_pressure_weighted ≈ weights[surface_rows[4]] * residual[surface_rows[4]]
    @test summary.surface_pressure_raw ≈ ASTRA.surface_pressure_log_mismatch(
        ASTRA.cell_eos_state(problem, model, n).pressure_dyn_cm2,
        ASTRA.outer_match_pressure_dyn_cm2(problem, model),
    )
    @test summary.surface_pressure_weighted ≈ summary.surface_pressure_raw
    @test summary.photospheric_face_temperature_k > 0.0
    @test summary.match_temperature_k > 0.0
    @test summary.photospheric_face_pressure_dyn_cm2 > 0.0
    @test summary.match_pressure_dyn_cm2 > 0.0
end
