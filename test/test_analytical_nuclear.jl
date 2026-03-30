@testset "analytical nuclear" begin
    composition = Composition(0.70, 0.28, 0.02)
    nuclear = ASTRA.Microphysics.AnalyticalNuclear()

    cool = nuclear(1.0, 5.0e6, composition)
    solar_like = nuclear(150.0, 1.5e7, composition)
    hot = nuclear(1.0, 3.0e7, composition)
    hot_cno = nuclear(150.0, 3.0e7, composition)

    @test hot.energy_rate_erg_g_s > cool.energy_rate_erg_g_s
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
    fd_temperature =
        (
            nuclear(150.0, 1.5e7 + 1.0, composition).energy_rate_erg_g_s -
            nuclear(150.0, 1.5e7 - 1.0, composition).energy_rate_erg_g_s
        ) / 2.0
    fd_density =
        (
            nuclear(150.0 + 1.0e-6, 1.5e7, composition).energy_rate_erg_g_s -
            nuclear(150.0 - 1.0e-6, 1.5e7, composition).energy_rate_erg_g_s
        ) / (2.0e-6)
    @test isapprox(dεdT, fd_temperature; rtol = 1.0e-4, atol = 1.0e-8)
    @test isapprox(dεdρ, fd_density; rtol = 1.0e-4, atol = 1.0e-8)
end
