@testset "armijo merit validation payload" begin
    problem = ASTRA.build_toy_problem(n_cells = 12)
    guess = ASTRA.initialize_state(problem)
    result = ASTRA.solve_structure(problem; state = guess)

    payload = ASTRA.build_armijo_merit_validation_payload(
        "default-12",
        problem,
        result;
        seed_label = "default",
    )

    @test payload.fixture_label == "default-12"
    @test payload.seed_label == "default"
    @test payload.n_cells == 12
    @test payload.accepted_step_count == result.diagnostics.accepted_step_count
    @test payload.rejected_trial_count == result.diagnostics.rejected_trial_count
    @test payload.final_residual_norm == result.diagnostics.residual_norm
    @test payload.final_weighted_residual_norm == result.diagnostics.weighted_residual_norm
    @test payload.final_merit == result.diagnostics.merit_value
    @test payload.predicted_decrease_history == result.diagnostics.predicted_decrease_history
    @test payload.actual_decrease_history == result.diagnostics.actual_decrease_history
    @test payload.decrease_ratio_history == result.diagnostics.decrease_ratio_history
    @test payload.accepted_dominant_family in
          Union{Nothing,Symbol}[(nothing), :center, :geometry, :hydrostatic, :luminosity, :interior_transport, :outer_transport, :surface]
    @test payload.accepted_dominant_surface_family in
          Union{Nothing,Symbol}[(nothing), :surface_radius, :surface_luminosity, :surface_temperature, :surface_pressure]
    @test payload.accepted_outer_boundary === nothing ||
          (payload.accepted_outer_boundary.present &&
           payload.accepted_outer_boundary.outer_transport_weighted ==
           result.diagnostics.accepted_trial_history[end].outer_boundary.outer_transport_weighted &&
           payload.accepted_outer_boundary.surface_temperature_weighted ==
           result.diagnostics.accepted_trial_history[end].outer_boundary.surface_temperature_weighted &&
           payload.accepted_outer_boundary.surface_pressure_weighted ==
           result.diagnostics.accepted_trial_history[end].outer_boundary.surface_pressure_weighted &&
           payload.accepted_outer_boundary.match_temperature_k ==
           result.diagnostics.accepted_trial_history[end].outer_boundary.match_temperature_k &&
           payload.accepted_outer_boundary.match_pressure_dyn_cm2 ==
           result.diagnostics.accepted_trial_history[end].outer_boundary.match_pressure_dyn_cm2)
    @test payload.accepted_transport_hotspot === nothing ||
          payload.accepted_transport_hotspot.location in (:interior, :outer)
    @test payload.best_rejected_trial === nothing ||
          payload.best_rejected_trial.row_family_merit.dominant_family in
          (:center, :geometry, :hydrostatic, :luminosity, :interior_transport, :outer_transport, :surface)
    @test payload.best_rejected_dominant_surface_family in
          Union{Nothing,Symbol}[(nothing), :surface_radius, :surface_luminosity, :surface_temperature, :surface_pressure]
    @test payload.best_rejected_outer_boundary === nothing ||
          (payload.best_rejected_outer_boundary.present &&
           payload.best_rejected_outer_boundary.outer_transport_weighted ==
           result.diagnostics.best_rejected_trial.outer_boundary.outer_transport_weighted &&
           payload.best_rejected_outer_boundary.surface_temperature_weighted ==
           result.diagnostics.best_rejected_trial.outer_boundary.surface_temperature_weighted &&
           payload.best_rejected_outer_boundary.surface_pressure_weighted ==
           result.diagnostics.best_rejected_trial.outer_boundary.surface_pressure_weighted &&
           payload.best_rejected_outer_boundary.match_temperature_k ==
           result.diagnostics.best_rejected_trial.outer_boundary.match_temperature_k &&
           payload.best_rejected_outer_boundary.match_pressure_dyn_cm2 ==
           result.diagnostics.best_rejected_trial.outer_boundary.match_pressure_dyn_cm2)
    @test payload.best_rejected_transport_hotspot === nothing ||
          payload.best_rejected_transport_hotspot.location in (:interior, :outer)
    @test payload.used_regularized_fallback isa Bool
end
