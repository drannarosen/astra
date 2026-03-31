@testset "surface temperature semantics audit artifacts" begin
    mktempdir() do tmpdir
        audit_dir = joinpath(tmpdir, "audit")
        mkpath(audit_dir)
        julia = joinpath(Sys.BINDIR, Base.julia_exename())
        project = normpath(joinpath(@__DIR__, ".."))
        script = normpath(
            joinpath(@__DIR__, "..", "scripts", "run_surface_temperature_semantics_audit.jl"),
        )
        run(`$julia --project=$project $script $audit_dir`)

        default_payload = read(joinpath(audit_dir, "default-12.toml"), String)
        manifest = read(joinpath(audit_dir, "manifest.txt"), String)
        files = sort(readdir(audit_dir))

        @test occursin("accepted_outer_boundary.surface_temperature_k", default_payload)
        @test occursin("accepted_outer_boundary.transport_temperature_offset_k", default_payload)
        @test occursin("accepted_outer_boundary.surface_to_photosphere_log_gap", default_payload)
        @test occursin("accepted_outer_boundary.match_to_photosphere_log_gap", default_payload)
        @test occursin("accepted_outer_boundary.surface_to_match_log_gap", default_payload)
        @test occursin(
            "accepted_outer_boundary.transport_temperature_offset_fraction",
            default_payload,
        )
        @test occursin("default-12.toml", manifest)
        @test files == [
            "default-12.toml",
            "manifest.txt",
            "perturb-a1e-6-case-01.toml",
            "perturb-a1e-6-case-02.toml",
            "perturb-a1e-6-case-03.toml",
        ]
    end
end
