@testset "outer boundary ownership audit artifacts" begin
    mktempdir() do tmpdir
        audit_dir = joinpath(tmpdir, "audit")
        mkpath(audit_dir)
        write(joinpath(audit_dir, "cells-6.toml"), "stale = true\n")
        julia = joinpath(Sys.BINDIR, Base.julia_exename())
        run(`$julia --project=. scripts/run_outer_boundary_ownership_audit.jl $audit_dir`)

        default_payload = read(joinpath(audit_dir, "default-12.toml"), String)
        manifest = read(joinpath(audit_dir, "manifest.txt"), String)
        files = sort(readdir(audit_dir))

        @test occursin("temperature_contract_log_gap", default_payload)
        @test occursin("pressure_contract_log_gap", default_payload)
        @test occursin("accepted_outer_boundary.current_match_temperature_k", default_payload)
        @test occursin("accepted_outer_boundary.fitting_point_temperature_k", default_payload)
        @test occursin("best_rejected_outer_boundary.temperature_contract_log_gap", default_payload)
        @test occursin("best_rejected_outer_boundary.pressure_contract_log_gap", default_payload)
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
