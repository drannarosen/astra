@testset "microphysics" begin
    composition = Composition(0.70, 0.28, 0.02)
    bundle = ASTRA.default_microphysics()
    eos = bundle.eos(1.0, 1.5e7, composition)
    opacity = bundle.opacity(1.0, 1.5e7, composition)
    nuclear = bundle.nuclear(150.0, 1.5e7, composition)
    convection = bundle.convection(0.2, eos, opacity)

    @test eos.pressure_dyn_cm2 > 0.0
    @test eos.gas_pressure_fraction > 0.0
    @test opacity.opacity_cm2_g > 0.0
    @test nuclear.energy_rate_erg_g_s >= 0.0
    @test convection.transport_regime in (:radiative, :convective)
end
