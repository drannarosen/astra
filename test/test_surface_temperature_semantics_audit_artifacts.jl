@testset "surface temperature semantics audit artifacts" begin
    committed_audit_dir = normpath(
        joinpath(@__DIR__, "..", "artifacts", "validation", "2026-03-30-surface-temperature-semantics-audit"),
    )
    default_payload = read(joinpath(committed_audit_dir, "default-12.toml"), String)
    manifest = read(joinpath(committed_audit_dir, "manifest.txt"), String)
    files = sort(readdir(committed_audit_dir))

    @test occursin("accepted_dominant_surface_family = surface_pressure", default_payload)
    @test occursin("accepted_outer_boundary.match_to_photosphere_log_gap = 0.0", default_payload)
    @test occursin(
        "accepted_outer_boundary.surface_to_match_log_gap = 0.06615610172518238",
        default_payload,
    )
    @test occursin("accepted_transport_hotspot.location = outer", default_payload)
    @test occursin("default-12.toml", manifest)
    @test files == [
        "default-12.toml",
        "manifest.txt",
        "perturb-a1e-6-case-01.toml",
        "perturb-a1e-6-case-02.toml",
        "perturb-a1e-6-case-03.toml",
    ]
end
