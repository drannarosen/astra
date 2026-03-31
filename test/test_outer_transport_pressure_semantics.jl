@testset "outer transport pressure semantics" begin
    problem = ASTRA.build_toy_problem(n_cells = 12)
    model = ASTRA.initialize_state(problem)

    semantics = ASTRA.outer_transport_pressure_semantics(problem, model)

    @test semantics.photospheric_face_pressure_dyn_cm2 > 0.0
    @test semantics.selected_pressure_target_dyn_cm2 > 0.0
    @test semantics.transport_pressure_target_dyn_cm2 > 0.0
    @test semantics.transport_pressure_target_dyn_cm2 ≈
          semantics.photospheric_face_pressure_dyn_cm2
    @test semantics.selected_pressure_target_dyn_cm2 ≈
          ASTRA._selected_pressure_target_dyn_cm2(problem, model)
    @test semantics.selected_to_transport_log_gap ≈
          log(semantics.selected_pressure_target_dyn_cm2) -
          log(semantics.transport_pressure_target_dyn_cm2)
end
