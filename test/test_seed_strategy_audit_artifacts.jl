@testset "seed strategy audit artifacts" begin
    committed_audit_dir = normpath(
        joinpath(@__DIR__, "..", "artifacts", "validation", "2026-03-31-seed-strategy-audit"),
    )

    @test isdir(committed_audit_dir)

    mktempdir() do tmpdir
        audit_dir = joinpath(tmpdir, "audit")
        mkpath(audit_dir)

        julia = joinpath(Sys.BINDIR, Base.julia_exename())
        project = normpath(joinpath(@__DIR__, ".."))
        script = normpath(joinpath(@__DIR__, "..", "scripts", "run_seed_strategy_audit.jl"))

        run(`$julia --project=$project $script $audit_dir`)

        committed_files = sort(readdir(committed_audit_dir))
        regenerated_files = sort(readdir(audit_dir))
        @test regenerated_files == committed_files

        manifest = read(joinpath(audit_dir, "manifest.txt"), String)
        bootstrap_payload = read(joinpath(audit_dir, "bootstrap_default-default-12.toml"), String)
        pms_like_payload = read(joinpath(audit_dir, "convective_pms_like-default-12.toml"), String)

        @test occursin("seed_label = bootstrap_default", manifest)
        @test occursin("seed_label = convective_pms_like", manifest)
        @test occursin("initial_merit = ", manifest)
        @test occursin("initial_dominant_family = ", manifest)
        @test occursin("accepted_outer_boundary_dominant_family = ", manifest)
        @test occursin("accepted_surface_pressure_bridge_dominant = ", manifest)

        @test occursin("seed_label = bootstrap_default", bootstrap_payload)
        @test occursin("initial_merit = ", bootstrap_payload)
        @test occursin("accepted_surface_pressure_bridge_dominant = true", bootstrap_payload)
        @test occursin("seed_label = convective_pms_like", pms_like_payload)
        @test occursin("initial_merit = ", pms_like_payload)
        @test occursin("accepted_outer_boundary_dominant_family = ", pms_like_payload)

        for filename in committed_files
            @test read(joinpath(audit_dir, filename), String) ==
                  read(joinpath(committed_audit_dir, filename), String)
        end
    end
end
