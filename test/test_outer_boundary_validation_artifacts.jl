@testset "outer boundary validation artifacts" begin
    mktempdir() do tmpdir
        bundle = ASTRA.run_armijo_merit_validation_suite(tmpdir)
        manifest = read(bundle.manifest_path, String)
        payload = read(first(bundle.payload_paths), String)

        @test occursin("accepted_dominant_surface_family", manifest)
        @test occursin("best_rejected_dominant_surface_family", manifest)
        @test occursin("accepted_outer_boundary.outer_transport_weighted", payload)
        @test occursin("accepted_outer_boundary.surface_temperature_weighted", payload)
        @test occursin("accepted_outer_boundary.surface_pressure_weighted", payload)
        @test occursin("accepted_outer_boundary.match_temperature_k", payload)
        @test occursin("accepted_outer_boundary.match_pressure_dyn_cm2", payload)
    end
end
