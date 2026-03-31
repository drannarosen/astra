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
    @test summary.surface_pressure_ratio ≈
          ASTRA.cell_eos_state(problem, model, n).pressure_dyn_cm2 /
          ASTRA.outer_match_pressure_dyn_cm2(problem, model)
    @test summary.surface_pressure_log_mismatch ≈ summary.surface_pressure_raw
    @test summary.surface_pressure_weighted ≈ summary.surface_pressure_raw
    @test summary.photospheric_face_temperature_k > 0.0
    @test summary.match_temperature_k > 0.0
    @test summary.photospheric_face_pressure_dyn_cm2 > 0.0
    @test summary.match_pressure_dyn_cm2 > 0.0
    semantics = ASTRA.surface_temperature_semantics(problem, model)
    terms = ASTRA.outer_boundary_fitting_point_terms(problem, model)
    @test summary.surface_temperature_k ≈ semantics.surface_temperature_k
    @test summary.transport_temperature_offset_k ≈ semantics.transport_temperature_offset_k
    @test summary.surface_to_photosphere_log_gap ≈ semantics.surface_to_photosphere_log_gap
    @test summary.match_to_photosphere_log_gap ≈ semantics.match_to_photosphere_log_gap
    @test summary.surface_to_match_log_gap ≈ semantics.surface_to_match_log_gap
    @test summary.transport_temperature_offset_fraction ≈
          semantics.transport_temperature_offset_fraction
    @test summary.current_match_temperature_k ≈ terms.current_match_temperature_k
    @test summary.fitting_point_temperature_k ≈ terms.fitting_point_temperature_k
    @test summary.temperature_contract_log_gap ≈ terms.temperature_contract_log_gap
    @test summary.match_to_photosphere_log_gap ≈ 0.0 atol = 1.0e-12
    @test summary.surface_to_match_log_gap ≈ summary.surface_to_photosphere_log_gap
    @test summary.current_match_pressure_dyn_cm2 ≈ terms.current_match_pressure_dyn_cm2
    @test summary.fitting_point_pressure_dyn_cm2 ≈ terms.fitting_point_pressure_dyn_cm2
    @test summary.pressure_contract_log_gap ≈ terms.pressure_contract_log_gap
    @test summary.pressure_contract_log_gap ≈ 0.0 atol = 1.0e-12
end
