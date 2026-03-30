@testset "analytical eos" begin
    composition = Composition(0.70, 0.28, 0.02)
    eos = ASTRA.Microphysics.AnalyticalGasRadiationEOS()

    state = eos(150.0, 1.5e7, composition)
    outer_state = eos(1.0e-7, 1.0e5, composition)

    @test state.pressure_dyn_cm2 > 0.0
    @test 0.0 < state.gas_pressure_fraction <= 1.0
    @test state.adiabatic_gradient > 0.0
    @test state.specific_heat_erg_g_k > 0.0
    @test outer_state.pressure_dyn_cm2 > 0.0
    @test 0.0 < outer_state.gas_pressure_fraction <= 1.0
    @test outer_state.adiabatic_gradient > 0.0
    @test outer_state.specific_heat_erg_g_k > 0.0

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
    @test isapprox(dPdT, fd_temperature; rtol = 1.0e-4, atol = 1.0e-8)
    @test isapprox(dPdρ, fd_density; rtol = 1.0e-4, atol = 1.0e-8)
    @test isapprox(outer_dPdT, outer_fd_temperature; rtol = 1.0e-4, atol = 1.0e-8)
    @test isapprox(outer_dPdρ, outer_fd_density; rtol = 1.0e-4, atol = 1.0e-8)
end
