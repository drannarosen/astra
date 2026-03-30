@testset "analytical energy sources" begin
    problem = ASTRA.build_toy_problem(n_cells = 6)
    model = initialize_state(problem)
    history = ASTRA.with_previous_thermodynamic_state(
        model;
        previous_log_temperature_cell_k = model.structure.log_temperature_cell_k .- log(1.01),
        previous_log_density_cell_g_cm3 = model.structure.log_density_cell_g_cm3 .+ log(1.01),
        timestep_s = 1.0e11,
        previous_timestep_s = 0.9e11,
        accepted_steps = 1,
    )

    sources = ASTRA.energy_source_terms(problem, model, 2)
    history_sources = ASTRA.energy_source_terms(problem, history, 2)
    eps_grav = ASTRA.Microphysics.eps_grav_from_cp(
        temperature_k = 1.5e7,
        specific_heat_erg_g_k = 1.0e8,
        adiabatic_gradient = 0.4,
        chi_temperature = 1.0,
        chi_density = 1.0,
        dlog_temperature_dt = 1.0e-14,
        dlog_density_dt = -2.0e-14,
    )

    @test sources.eps_nuc_erg_g_s > 0.0
    @test isfinite(sources.eps_grav_erg_g_s)
    @test isfinite(sources.eps_nu_erg_g_s)
    @test isfinite(sources.eps_total_erg_g_s)
    @test sources.eps_total_erg_g_s ≈
        sources.eps_nuc_erg_g_s + sources.eps_grav_erg_g_s - sources.eps_nu_erg_g_s
    @test isfinite(eps_grav)
    @test isfinite(history_sources.eps_grav_erg_g_s)
    @test history_sources.eps_grav_owner == :evolution_history
    @test history_sources.eps_grav_erg_g_s != 0.0
    @test history_sources.eps_nu_erg_g_s >= 0.0
    @test history_sources.eps_total_erg_g_s ≈
        history_sources.eps_nuc_erg_g_s +
        history_sources.eps_grav_erg_g_s -
        history_sources.eps_nu_erg_g_s
end
