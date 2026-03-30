@testset "microphysics" begin
    composition = Composition(0.70, 0.28, 0.02)
    bundle = ASTRA.default_microphysics()
    eos = bundle.eos(1.0, 1.5e7, composition)
    opacity = bundle.opacity(1.0, 1.5e7, composition)
    nuclear = bundle.nuclear(150.0, 1.5e7, composition)
    convection = bundle.convection(0.2, eos, opacity)

    @test eos.pressure_dyn_cm2 > 0.0
    @test 0.0 < eos.gas_pressure_fraction <= 1.0
    @test isfinite(eos.adiabatic_gradient)
    @test isfinite(eos.specific_heat_erg_g_k)
    @test opacity.opacity_cm2_g > 0.0
    @test opacity.source == :analytical_opacity
    @test nuclear.energy_rate_erg_g_s >= 0.0
    @test nuclear.source == :analytical_nuclear
    @test convection.transport_regime in (:radiative, :convective)
end
