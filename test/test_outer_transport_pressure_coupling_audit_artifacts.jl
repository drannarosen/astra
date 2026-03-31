@testset "outer transport pressure coupling audit artifacts" begin
    committed_audit_dir = normpath(
        joinpath(
            @__DIR__,
            "..",
            "artifacts",
            "validation",
            "2026-03-31-outer-transport-pressure-coupling-audit",
        ),
    )

    @test isdir(committed_audit_dir)

    mktempdir() do tmpdir
        audit_dir = joinpath(tmpdir, "audit")
        mkpath(audit_dir)

        julia = joinpath(Sys.BINDIR, Base.julia_exename())
        project = normpath(joinpath(@__DIR__, ".."))
        script = normpath(
            joinpath(
                @__DIR__,
                "..",
                "scripts",
                "run_outer_transport_pressure_coupling_audit.jl",
            ),
        )

        run(`$julia --project=$project $script $audit_dir`)

        committed_files = sort(readdir(committed_audit_dir))
        regenerated_files = sort(readdir(audit_dir))
        @test regenerated_files == committed_files

        manifest = read(joinpath(audit_dir, "manifest.txt"), String)
        @test occursin("outer_transport_pressure_label = photospheric_face", manifest)
        @test occursin("outer_transport_pressure_label = selected_pressure_target", manifest)
        @test occursin("accepted_transport_hotspot_location = ", manifest)
        @test occursin("accepted_outer_boundary_dominant_family = ", manifest)

        for filename in committed_files
            @test read(joinpath(audit_dir, filename), String) ==
                  read(joinpath(committed_audit_dir, filename), String)
        end
    end
end
