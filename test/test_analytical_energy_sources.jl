@testset "analytical energy sources" begin
    problem = ASTRA.build_toy_problem(n_cells = 6)
    model = initialize_state(problem)

    sources = ASTRA.energy_source_terms(problem, model, 2)

    @test sources.eps_nuc_erg_g_s > 0.0
    @test isfinite(sources.eps_grav_erg_g_s)
    @test isfinite(sources.eps_nu_erg_g_s)
    @test isfinite(sources.eps_total_erg_g_s)
    @test sources.eps_total_erg_g_s ≈
        sources.eps_nuc_erg_g_s + sources.eps_grav_erg_g_s - sources.eps_nu_erg_g_s
end
