@testset "outer boundary ownership audit artifacts" begin
    mktempdir() do tmpdir
        audit_dir = joinpath(tmpdir, "audit")
        julia = joinpath(homedir(), ".juliaup", "bin", "julia")
        run(`$julia --project=. scripts/run_outer_boundary_ownership_audit.jl $audit_dir`)

        default_payload = read(joinpath(audit_dir, "default-12.toml"), String)
        manifest = read(joinpath(audit_dir, "manifest.txt"), String)

        @test occursin("temperature_contract_log_gap", default_payload)
        @test occursin("pressure_contract_log_gap", default_payload)
        @test occursin("accepted_outer_boundary.current_match_temperature_k", default_payload)
        @test occursin("accepted_outer_boundary.fitting_point_temperature_k", default_payload)
        @test occursin("default-12.toml", manifest)
    end
end
