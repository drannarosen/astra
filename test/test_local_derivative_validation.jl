@testset "local derivative validation" begin
    problem = ASTRA.build_toy_problem(n_cells = 6)
    model = initialize_state(problem)
    k = 2
    density_g_cm3 = exp(model.structure.log_density_cell_g_cm3[k])
    temperature_k = exp(model.structure.log_temperature_cell_k[k])
    composition = ASTRA.cell_composition(problem, model, k)

    fd = ASTRA.finite_difference_temperature_gradient_sensitivity(problem, model, k)
    analytic = ASTRA.helper_temperature_gradient_sensitivity(problem, model, k)
    density_fd = ASTRA.finite_difference_density_gradient_sensitivity(problem, model, k)
    density_analytic = ASTRA.helper_density_gradient_sensitivity(problem, model, k)

    @test isfinite(fd)
    @test isfinite(analytic)
    @test isapprox(analytic, fd; rtol = 1.0e-4, atol = 1.0e-8)
    @test isfinite(density_fd)
    @test isfinite(density_analytic)
    @test isapprox(density_analytic, density_fd; rtol = 1.0e-4, atol = 1.0e-8)

    eos_state = problem.microphysics.eos(density_g_cm3, temperature_k, composition)
    degenerate_eos = ASTRA.Microphysics.AnalyticalGasRadiationEOS(include_degeneracy = true)
    coulomb_eos = ASTRA.Microphysics.AnalyticalGasRadiationEOS(include_coulomb = true)
    extreme_eos = ASTRA.Microphysics.AnalyticalGasRadiationEOS(
        include_degeneracy = true,
        include_coulomb = true,
    )
    opacity_state = problem.microphysics.opacity(density_g_cm3, temperature_k, composition)
    nuclear_state = problem.microphysics.nuclear(density_g_cm3, temperature_k, composition)
    screened_nuclear = ASTRA.Microphysics.AnalyticalNuclear(include_screening = true)
    screened_nuclear_state = screened_nuclear(density_g_cm3, temperature_k, composition)

    @test isfinite(eos_state.pressure_dyn_cm2)
    @test 0.0 < eos_state.gas_pressure_fraction <= 1.0
    @test isfinite(eos_state.adiabatic_gradient)
    @test isfinite(eos_state.specific_heat_erg_g_k)
    @test isfinite(eos_state.chi_rho)
    @test isfinite(eos_state.chi_T)
    @test opacity_state.source == :analytical_opacity
    @test nuclear_state.source == :analytical_nuclear
    @test screened_nuclear_state.energy_rate_erg_g_s >= nuclear_state.energy_rate_erg_g_s

    degenerate_density_fd =
        (
            degenerate_eos(density_g_cm3 * 1.0e0 + 1.0e-6, temperature_k, composition).pressure_dyn_cm2 -
            degenerate_eos(density_g_cm3 * 1.0e0 - 1.0e-6, temperature_k, composition).pressure_dyn_cm2
        ) / (2.0e-6)
    degenerate_temperature_fd =
        (
            degenerate_eos(density_g_cm3, temperature_k + 1.0, composition).pressure_dyn_cm2 -
            degenerate_eos(density_g_cm3, temperature_k - 1.0, composition).pressure_dyn_cm2
        ) / 2.0
    degenerate_density_analytic = ASTRA.Microphysics.pressure_density_derivative(
        degenerate_eos,
        density_g_cm3,
        temperature_k,
        composition,
    )
    degenerate_temperature_analytic = ASTRA.Microphysics.pressure_temperature_derivative(
        degenerate_eos,
        density_g_cm3,
        temperature_k,
        composition,
    )
    coulomb_density_analytic = ASTRA.Microphysics.pressure_density_derivative(
        coulomb_eos,
        density_g_cm3,
        temperature_k,
        composition,
    )
    coulomb_temperature_analytic = ASTRA.Microphysics.pressure_temperature_derivative(
        coulomb_eos,
        density_g_cm3,
        temperature_k,
        composition,
    )
    extreme_state = extreme_eos(1.0e8, 3.0e5, composition)
    extreme_density_analytic = ASTRA.Microphysics.pressure_density_derivative(
        extreme_eos,
        1.0e8,
        3.0e5,
        composition,
    )
    extreme_temperature_analytic = ASTRA.Microphysics.pressure_temperature_derivative(
        extreme_eos,
        1.0e8,
        3.0e5,
        composition,
    )

    pressure_density_fd =
        (
            problem.microphysics.eos(density_g_cm3 * 1.0e0 + 1.0e-6, temperature_k, composition).pressure_dyn_cm2 -
            problem.microphysics.eos(density_g_cm3 * 1.0e0 - 1.0e-6, temperature_k, composition).pressure_dyn_cm2
        ) / (2.0e-6)
    pressure_density_analytic = ASTRA.Microphysics.pressure_density_derivative(
        problem.microphysics.eos,
        density_g_cm3,
        temperature_k,
        composition,
    )

    opacity_density_fd =
        (
            problem.microphysics.opacity(density_g_cm3 * 1.0e0 + 1.0e-6, temperature_k, composition).opacity_cm2_g -
            problem.microphysics.opacity(density_g_cm3 * 1.0e0 - 1.0e-6, temperature_k, composition).opacity_cm2_g
        ) / (2.0e-6)
    opacity_density_analytic = ASTRA.Microphysics.opacity_density_derivative(
        problem.microphysics.opacity,
        density_g_cm3,
        temperature_k,
        composition,
    )

    nuclear_density_fd =
        (
            problem.microphysics.nuclear(density_g_cm3 * 1.0e0 + 1.0e-6, temperature_k, composition).energy_rate_erg_g_s -
            problem.microphysics.nuclear(density_g_cm3 * 1.0e0 - 1.0e-6, temperature_k, composition).energy_rate_erg_g_s
        ) / (2.0e-6)
    nuclear_density_analytic = ASTRA.Microphysics.nuclear_density_derivative(
        problem.microphysics.nuclear,
        density_g_cm3,
        temperature_k,
        composition,
    )
    screened_nuclear_density_fd =
        (
            screened_nuclear(density_g_cm3 * 1.0e0 + 1.0e-6, temperature_k, composition).energy_rate_erg_g_s -
            screened_nuclear(density_g_cm3 * 1.0e0 - 1.0e-6, temperature_k, composition).energy_rate_erg_g_s
        ) / (2.0e-6)
    screened_nuclear_density_analytic = ASTRA.Microphysics.nuclear_density_derivative(
        screened_nuclear,
        density_g_cm3,
        temperature_k,
        composition,
    )
    screened_nuclear_temperature_fd =
        (
            screened_nuclear(density_g_cm3, temperature_k + 1.0, composition).energy_rate_erg_g_s -
            screened_nuclear(density_g_cm3, temperature_k - 1.0, composition).energy_rate_erg_g_s
        ) / 2.0
    screened_nuclear_temperature_analytic = ASTRA.Microphysics.nuclear_temperature_derivative(
        screened_nuclear,
        density_g_cm3,
        temperature_k,
        composition,
    )

    @test isfinite(pressure_density_fd)
    @test isfinite(pressure_density_analytic)
    @test isapprox(pressure_density_analytic, pressure_density_fd; rtol = 1.0e-6, atol = 1.0e-8)

    @test isfinite(opacity_density_fd)
    @test isfinite(opacity_density_analytic)
    @test isapprox(opacity_density_analytic, opacity_density_fd; rtol = 1.0e-6, atol = 1.0e-8)

    @test isfinite(nuclear_density_fd)
    @test isfinite(nuclear_density_analytic)
    @test isapprox(nuclear_density_analytic, nuclear_density_fd; rtol = 1.0e-6, atol = 1.0e-8)
    @test isfinite(degenerate_density_fd)
    @test isfinite(degenerate_temperature_fd)
    @test isfinite(degenerate_density_analytic)
    @test isfinite(degenerate_temperature_analytic)
    @test isfinite(coulomb_density_analytic)
    @test isfinite(coulomb_temperature_analytic)
    @test extreme_state.pressure_dyn_cm2 > 0.0
    @test isfinite(extreme_state.chi_rho)
    @test isfinite(extreme_state.chi_T)
    @test isfinite(extreme_density_analytic)
    @test isfinite(extreme_temperature_analytic)
    @test isfinite(screened_nuclear_density_fd)
    @test isfinite(screened_nuclear_density_analytic)
    @test isapprox(
        screened_nuclear_density_analytic,
        screened_nuclear_density_fd;
        rtol = 1.0e-6,
        atol = 1.0e-8,
    )
    @test isfinite(screened_nuclear_temperature_fd)
    @test isfinite(screened_nuclear_temperature_analytic)
    @test isapprox(
        screened_nuclear_temperature_analytic,
        screened_nuclear_temperature_fd;
        rtol = 1.0e-6,
        atol = 1.0e-8,
    )
end
