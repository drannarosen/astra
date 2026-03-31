using Test
using ASTRA

@testset "surface pressure semantics" begin
    problem = ASTRA.build_toy_problem(n_cells = 12)
    model = ASTRA.initialize_state(problem)

    semantics = ASTRA.surface_pressure_semantics(problem, model)

    @test semantics.surface_pressure_dyn_cm2 > 0.0
    @test semantics.photospheric_face_pressure_dyn_cm2 > 0.0
    @test semantics.match_pressure_dyn_cm2 > 0.0
    @test semantics.hydrostatic_pressure_offset_dyn_cm2 > 0.0
    @test semantics.match_to_photosphere_log_gap > 0.0
    @test semantics.surface_to_match_log_gap ≈
          semantics.surface_to_photosphere_log_gap - semantics.match_to_photosphere_log_gap
    @test semantics.surface_to_match_log_gap ≈ ASTRA.surface_pressure_log_mismatch(
        semantics.surface_pressure_dyn_cm2,
        semantics.match_pressure_dyn_cm2,
    )
    @test semantics.hydrostatic_pressure_offset_fraction > 0.0
end
