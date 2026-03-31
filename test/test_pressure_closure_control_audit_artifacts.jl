@testset "pressure closure control audit artifacts" begin
    committed_audit_dir = normpath(
        joinpath(
            @__DIR__,
            "..",
            "artifacts",
            "validation",
            "2026-03-31-pressure-closure-control-audit",
        ),
    )

    @test isdir(committed_audit_dir)

    mktempdir() do tmpdir
        audit_dir = joinpath(tmpdir, "audit")
        mkpath(audit_dir)

        julia = joinpath(Sys.BINDIR, Base.julia_exename())
        project = normpath(joinpath(@__DIR__, ".."))
        script = normpath(
            joinpath(@__DIR__, "..", "scripts", "run_pressure_closure_control_audit.jl"),
        )

        run(`$julia --project=$project $script $audit_dir`)

        committed_files = sort(readdir(committed_audit_dir))
        regenerated_files = sort(readdir(audit_dir))
        @test regenerated_files == committed_files

        manifest = read(joinpath(audit_dir, "manifest.txt"), String)

        @test occursin("pressure_closure_label = bridge", manifest)
        @test occursin("pressure_closure_label = photosphere_control", manifest)
        @test occursin("accepted_dominant_surface_family = ", manifest)
        @test occursin("accepted_surface_pressure_bridge_dominant = ", manifest)

        for filename in committed_files
            @test read(joinpath(audit_dir, filename), String) ==
                  read(joinpath(committed_audit_dir, filename), String)
        end
    end
end
