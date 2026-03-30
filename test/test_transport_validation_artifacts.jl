@testset "transport validation artifacts" begin
    mktempdir() do tmpdir
        bundle = ASTRA.run_armijo_merit_validation_suite(tmpdir)
        manifest = read(bundle.manifest_path, String)
        payload = read(first(bundle.payload_paths), String)

        @test occursin("accepted_transport_dominant_family", manifest)
        @test occursin("best_rejected_transport_dominant_family", manifest)
        @test occursin("accepted_transport_dominant_family", payload)
        @test occursin("best_rejected_transport_dominant_family", payload)
    end
end
