using Test
using ASTRA

@testset "outer boundary fitting-point terms" begin
    problem = ASTRA.build_toy_problem(n_cells = 12)
    model = ASTRA.initialize_state(problem)
    terms = ASTRA.outer_boundary_fitting_point_terms(problem, model)

    @test terms.photospheric_face_temperature_k > 0.0
    @test terms.photospheric_face_pressure_dyn_cm2 > 0.0
    @test terms.half_cell_column_density_g_cm2 > 0.0
    @test terms.half_cell_optical_depth > 0.0
    @test terms.hydrostatic_pressure_offset_dyn_cm2 > 0.0
    @test terms.current_match_pressure_dyn_cm2 ≈
          terms.photospheric_face_pressure_dyn_cm2 + terms.hydrostatic_pressure_offset_dyn_cm2
    @test terms.current_match_temperature_k ≈ terms.photospheric_face_temperature_k
    @test terms.fitting_point_temperature_k ≈
          terms.photospheric_face_temperature_k + terms.transport_temperature_offset_k
    @test terms.temperature_contract_log_gap ≈
          log(terms.current_match_temperature_k) - log(terms.fitting_point_temperature_k)
end
