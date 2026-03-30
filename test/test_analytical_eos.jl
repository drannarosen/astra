@testset "analytical eos" begin
    composition = Composition(0.70, 0.28, 0.02)
    eos = ASTRA.Microphysics.AnalyticalGasRadiationEOS()

    state = eos(150.0, 1.5e7, composition)

    @test state.pressure_dyn_cm2 > 0.0
    @test 0.0 < state.gas_pressure_fraction <= 1.0
    @test state.adiabatic_gradient > 0.0
    @test state.specific_heat_erg_g_k > 0.0

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
end
