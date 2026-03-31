using Test
using ASTRA

@testset "surface temperature semantics" begin
    problem = ASTRA.build_toy_problem(n_cells = 12)
    model = ASTRA.initialize_state(problem)
    residual = ASTRA.assemble_structure_residual(problem, model)
    weights = ASTRA.Solvers.residual_row_weights(problem, model)

    semantics = ASTRA.surface_temperature_semantics(problem, model)
    summary = ASTRA.Solvers.outer_boundary_row_summary(
        problem,
        model,
        residual;
        row_weights = weights,
    )

    @test semantics.surface_temperature_k > 0.0
    @test semantics.photospheric_face_temperature_k > 0.0
    @test semantics.match_temperature_k > 0.0
    @test semantics.transport_temperature_offset_k > 0.0
    @test semantics.surface_to_match_log_gap ≈
          semantics.surface_to_photosphere_log_gap - semantics.match_to_photosphere_log_gap
    @test semantics.surface_to_match_log_gap ≈ residual[summary.surface_temperature_row_index]
    @test abs(semantics.surface_to_photosphere_log_gap) < 1.0e-4
    @test abs(semantics.match_to_photosphere_log_gap) < 1.0e-4
    @test semantics.surface_to_match_log_gap ≈ semantics.surface_to_photosphere_log_gap
    @test semantics.transport_temperature_offset_fraction > 0.0

    @test summary.surface_temperature_k ≈ semantics.surface_temperature_k
    @test summary.photospheric_face_temperature_k ≈ semantics.photospheric_face_temperature_k
    @test summary.match_temperature_k ≈ semantics.match_temperature_k
    @test summary.transport_temperature_offset_k ≈ semantics.transport_temperature_offset_k
    @test summary.surface_to_photosphere_log_gap ≈ semantics.surface_to_photosphere_log_gap
    @test summary.match_to_photosphere_log_gap ≈ semantics.match_to_photosphere_log_gap
    @test summary.surface_to_match_log_gap ≈ semantics.surface_to_match_log_gap
    @test summary.transport_temperature_offset_fraction ≈
          semantics.transport_temperature_offset_fraction
end
