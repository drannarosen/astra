@testset "surface pressure semantics audit artifacts" begin
    committed_audit_dir = normpath(
        joinpath(@__DIR__, "..", "artifacts", "validation", "2026-03-31-surface-pressure-semantics-audit"),
    )

    @test isdir(committed_audit_dir)

    mktempdir() do tmpdir
        audit_dir = joinpath(tmpdir, "audit")
        mkpath(audit_dir)

        julia = joinpath(Sys.BINDIR, Base.julia_exename())
        project = normpath(joinpath(@__DIR__, ".."))
        script = normpath(
            joinpath(@__DIR__, "..", "scripts", "run_surface_pressure_semantics_audit.jl"),
        )

        run(`$julia --project=$project $script $audit_dir`)

        committed_files = sort(readdir(committed_audit_dir))
        regenerated_files = sort(readdir(audit_dir))
        @test regenerated_files == committed_files

        default_payload = read(joinpath(audit_dir, "default-12.toml"), String)
        @test occursin("accepted_dominant_surface_family = surface_pressure", default_payload)
        @test occursin(
            "accepted_outer_boundary.pressure_match_to_photosphere_log_gap = 46.46031816695854",
            default_payload,
        )
        @test occursin(
            "accepted_outer_boundary.pressure_surface_to_match_log_gap = -3.4009054493494055",
            default_payload,
        )
        @test occursin(
            "accepted_outer_boundary.hydrostatic_pressure_offset_fraction = 1.504734253824455e20",
            default_payload,
        )
        @test occursin("accepted_transport_hotspot.location = outer", default_payload)
        @test occursin("accepted_transport_hotspot.cell_index = 11", default_payload)

        for filename in committed_files
            @test read(joinpath(audit_dir, filename), String) ==
                  read(joinpath(committed_audit_dir, filename), String)
        end
    end
end
