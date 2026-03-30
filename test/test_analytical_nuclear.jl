@testset "analytical nuclear" begin
    composition = Composition(0.70, 0.28, 0.02)
    nuclear = ASTRA.Microphysics.AnalyticalNuclear()

    solar_like = nuclear(150.0, 1.5e7, composition)
    hot_cno = nuclear(150.0, 3.0e7, composition)

    @test solar_like.energy_rate_erg_g_s > 0.0
    @test hot_cno.energy_rate_erg_g_s > solar_like.energy_rate_erg_g_s
    @test solar_like.source == :analytical_nuclear

    dεdT = ASTRA.Microphysics.nuclear_temperature_derivative(
        nuclear,
        150.0,
        1.5e7,
        composition,
    )
    dεdρ = ASTRA.Microphysics.nuclear_density_derivative(
        nuclear,
        150.0,
        1.5e7,
        composition,
    )

    @test isfinite(dεdT)
    @test isfinite(dεdρ)
end
