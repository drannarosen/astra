@testset "surface pressure validation artifacts" begin
    mktempdir() do tmpdir
        bundle = ASTRA.run_armijo_merit_validation_suite(tmpdir)
        payload = read(first(bundle.payload_paths), String)

        @test occursin("accepted_outer_boundary.surface_pressure_ratio", payload)
        @test occursin("accepted_outer_boundary.surface_pressure_log_mismatch", payload)
        @test occursin("best_rejected_outer_boundary.surface_pressure_ratio", payload)
        @test occursin("best_rejected_outer_boundary.surface_pressure_log_mismatch", payload)
    end
end
