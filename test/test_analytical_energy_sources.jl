@testset "analytical energy sources" begin
    problem = ASTRA.build_toy_problem(n_cells = 6)
    model = initialize_state(problem)
    composition = ASTRA.Composition(0.70, 0.28, 0.02)
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
    eps_nu_cool = ASTRA.Microphysics.analytical_neutrino_loss_rate(1.0e4, 1.0e8, composition)
    eps_nu_mid = ASTRA.Microphysics.analytical_neutrino_loss_rate(1.0e4, 3.0e8, composition)
    eps_nu_hot = ASTRA.Microphysics.analytical_neutrino_loss_rate(1.0e4, 1.0e9, composition)

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
    @test_throws ArgumentError ASTRA.with_previous_thermodynamic_state(
        model;
        previous_log_temperature_cell_k = model.structure.log_temperature_cell_k .- log(1.01),
        previous_log_density_cell_g_cm3 = model.structure.log_density_cell_g_cm3 .+ log(1.01),
    )
    @test isfinite(eps_nu_cool)
    @test isfinite(eps_nu_mid)
    @test isfinite(eps_nu_hot)
    @test eps_nu_cool > 0.0
    @test eps_nu_cool < eps_nu_mid < eps_nu_hot
end

@testset "eps_grav uses EOS thermodynamic response terms" begin
    base_problem = ASTRA.build_toy_problem(n_cells = 6)
    flagged_eos = ASTRA.Microphysics.AnalyticalGasRadiationEOS(
        include_degeneracy = true,
        include_coulomb = true,
    )
    problem = ASTRA.StructureProblem(
        base_problem.formulation,
        base_problem.parameters,
        base_problem.composition,
        base_problem.grid,
        ASTRA.MicrophysicsBundle(
            flagged_eos,
            base_problem.microphysics.opacity,
            base_problem.microphysics.nuclear,
            base_problem.microphysics.convection,
        ),
        base_problem.solver,
    )
    model = initialize_state(problem)
    history = ASTRA.with_previous_thermodynamic_state(
        model;
        previous_log_temperature_cell_k = model.structure.log_temperature_cell_k .- log(1.02),
        previous_log_density_cell_g_cm3 = model.structure.log_density_cell_g_cm3 .+ log(1.01),
        timestep_s = 2.0e11,
        previous_timestep_s = 1.8e11,
        accepted_steps = 1,
    )

    k = 2
    density_g_cm3 = exp(history.structure.log_density_cell_g_cm3[k])
    temperature_k = exp(history.structure.log_temperature_cell_k[k])
    composition = ASTRA.Composition(0.70, 0.28, 0.02)
    eos_state = flagged_eos(density_g_cm3, temperature_k, composition)
    expected_eps_grav = ASTRA.Microphysics.eps_grav_from_cp(
        temperature_k = temperature_k,
        specific_heat_erg_g_k = eos_state.specific_heat_erg_g_k,
        adiabatic_gradient = eos_state.adiabatic_gradient,
        chi_temperature = eos_state.chi_T,
        chi_density = eos_state.chi_rho,
        dlog_temperature_dt = (
            history.structure.log_temperature_cell_k[k] -
            history.evolution.previous_log_temperature_cell_k[k]
        ) / history.evolution.timestep_s,
        dlog_density_dt = (
            history.structure.log_density_cell_g_cm3[k] -
            history.evolution.previous_log_density_cell_g_cm3[k]
        ) / history.evolution.timestep_s,
    )
    sources = ASTRA.energy_source_terms(problem, history, k)

    @test sources.eps_grav_owner == :evolution_history
    @test sources.eps_grav_erg_g_s ≈ expected_eps_grav rtol = 1.0e-12 atol = 1.0e-12
end
