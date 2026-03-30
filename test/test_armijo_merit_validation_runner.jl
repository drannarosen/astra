@testset "armijo merit validation runner" begin
    mktempdir() do tmpdir
        bundle = ASTRA.run_armijo_merit_validation_suite(tmpdir)

        @test isfile(bundle.manifest_path)
        @test !isempty(bundle.payload_paths)
        @test all(isfile, bundle.payload_paths)
        @test any(path -> occursin("default-12", basename(path)), bundle.payload_paths)
        @test any(path -> occursin("cells-24", basename(path)), bundle.payload_paths)
        @test any(path -> occursin("perturb", basename(path)), bundle.payload_paths)

        manifest = read(bundle.manifest_path, String)
        @test occursin("fixture_label = default-12", manifest)
        @test occursin("n_cells = 24", manifest)
        @test occursin("used_regularized_fallback", manifest)
    end
end
