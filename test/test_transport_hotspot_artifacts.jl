@testset "transport hotspot artifacts" begin
    mktempdir() do tmpdir
        bundle = ASTRA.run_armijo_merit_validation_suite(tmpdir)
        manifest = read(bundle.manifest_path, String)
        payload = read(first(bundle.payload_paths), String)

        @test occursin("accepted_transport_hotspot_location", manifest)
        @test occursin("accepted_transport_hotspot_cell_index", manifest)
        @test occursin("accepted_transport_hotspot.location", payload)
        @test occursin("accepted_transport_hotspot.gradient_term", payload)
        @test occursin("best_rejected_transport_hotspot.location", payload)
    end
end
