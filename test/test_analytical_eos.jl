@testset "analytical eos" begin
    composition = Composition(0.70, 0.28, 0.02)
    eos = ASTRA.Microphysics.AnalyticalGasRadiationEOS()
    degenerate = ASTRA.Microphysics.AnalyticalGasRadiationEOS(include_degeneracy = true)
    coulomb = ASTRA.Microphysics.AnalyticalGasRadiationEOS(include_coulomb = true)

    state = eos(150.0, 1.5e7, composition)
    outer_state = eos(1.0e-7, 1.0e5, composition)
    degenerate_state = degenerate(1.0e6, 1.0e7, composition)
    degenerate_base_state = eos(1.0e6, 1.0e7, composition)
    coulomb_state = coulomb(1.0e2, 1.0e7, composition)

    @test state.pressure_dyn_cm2 > 0.0
    @test 0.0 < state.gas_pressure_fraction <= 1.0
    @test state.adiabatic_gradient > 0.0
    @test state.specific_heat_erg_g_k > 0.0
    @test outer_state.pressure_dyn_cm2 > 0.0
    @test 0.0 < outer_state.gas_pressure_fraction <= 1.0
    @test outer_state.adiabatic_gradient > 0.0
    @test outer_state.specific_heat_erg_g_k > 0.0
    @test isfinite(state.chi_rho)
    @test isfinite(state.chi_T)
    @test isfinite(outer_state.chi_rho)
    @test isfinite(outer_state.chi_T)
    @test degenerate_state.pressure_dyn_cm2 > degenerate_base_state.pressure_dyn_cm2
    @test isfinite(coulomb_state.pressure_dyn_cm2)
    @test isfinite(degenerate_state.chi_rho)
    @test isfinite(degenerate_state.chi_T)
    @test isfinite(coulomb_state.chi_rho)
    @test isfinite(coulomb_state.chi_T)

    dPdT = ASTRA.Microphysics.pressure_temperature_derivative(
        eos,
        150.0,
        1.5e7,
        composition,
    )
    dPdρ = ASTRA.Microphysics.pressure_density_derivative(
        eos,
        150.0,
        1.5e7,
        composition,
    )

    @test isfinite(dPdT)
    @test isfinite(dPdρ)
    fd_temperature =
        (
            eos(150.0, 1.5e7 + 1.0, composition).pressure_dyn_cm2 -
            eos(150.0, 1.5e7 - 1.0, composition).pressure_dyn_cm2
        ) / 2.0
    fd_density =
        (
            eos(150.0 + 1.0e-6, 1.5e7, composition).pressure_dyn_cm2 -
            eos(150.0 - 1.0e-6, 1.5e7, composition).pressure_dyn_cm2
        ) / (2.0e-6)
    outer_dPdT = ASTRA.Microphysics.pressure_temperature_derivative(
        eos,
        1.0e-7,
        1.0e5,
        composition,
    )
    outer_dPdρ = ASTRA.Microphysics.pressure_density_derivative(
        eos,
        1.0e-7,
        1.0e5,
        composition,
    )
    outer_fd_temperature =
        (
            eos(1.0e-7, 1.0e5 + 1.0, composition).pressure_dyn_cm2 -
            eos(1.0e-7, 1.0e5 - 1.0, composition).pressure_dyn_cm2
        ) / 2.0
    outer_fd_density =
        (
            eos(1.0e-7 + 1.0e-9, 1.0e5, composition).pressure_dyn_cm2 -
            eos(max(1.0e-7 - 1.0e-9, 1.0e-12), 1.0e5, composition).pressure_dyn_cm2
        ) / (2.0e-9)
    coulomb_dPdT = ASTRA.Microphysics.pressure_temperature_derivative(
        coulomb,
        1.0e2,
        1.0e7,
        composition,
    )
    coulomb_dPdρ = ASTRA.Microphysics.pressure_density_derivative(
        coulomb,
        1.0e2,
        1.0e7,
        composition,
    )
    @test isapprox(dPdT, fd_temperature; rtol = 1.0e-4, atol = 1.0e-8)
    @test isapprox(dPdρ, fd_density; rtol = 1.0e-4, atol = 1.0e-8)
    @test isapprox(outer_dPdT, outer_fd_temperature; rtol = 1.0e-4, atol = 1.0e-8)
    @test isapprox(outer_dPdρ, outer_fd_density; rtol = 1.0e-4, atol = 1.0e-8)
    @test isfinite(coulomb_dPdT)
    @test isfinite(coulomb_dPdρ)
end
