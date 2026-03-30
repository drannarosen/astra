@testset "analytical nuclear" begin
    composition = Composition(0.70, 0.28, 0.02)
    nuclear = ASTRA.Microphysics.AnalyticalNuclear()
    screened = ASTRA.Microphysics.AnalyticalNuclear(include_screening = true)
    unscreened = ASTRA.Microphysics.AnalyticalNuclear(include_screening = false)
    he_burning = ASTRA.Microphysics.AnalyticalNuclear(include_3alpha = true)
    helium_rich = Composition(0.0, 0.98, 0.02)

    cool = nuclear(1.0, 5.0e6, composition)
    solar_like = nuclear(150.0, 1.5e7, composition)
    hot = nuclear(1.0, 3.0e7, composition)
    hot_cno = nuclear(150.0, 3.0e7, composition)
    solar_screened = screened(150.0, 1.5e7, composition)
    solar_unscreened = unscreened(150.0, 1.5e7, composition)
    triple_alpha = he_burning(1.0e4, 1.5e8, helium_rich)

    @test hot.energy_rate_erg_g_s > cool.energy_rate_erg_g_s
    @test solar_like.energy_rate_erg_g_s > 0.0
    @test hot_cno.energy_rate_erg_g_s > solar_like.energy_rate_erg_g_s
    @test solar_like.source == :analytical_nuclear
    @test solar_screened.energy_rate_erg_g_s > solar_unscreened.energy_rate_erg_g_s
    @test triple_alpha.energy_rate_erg_g_s > 0.0

    dεdT = ASTRA.Microphysics.nuclear_temperature_derivative(
        nuclear,
        150.0,
        1.5e7,
        composition,
    )
    screened_dεdT = ASTRA.Microphysics.nuclear_temperature_derivative(
        screened,
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
    screened_dεdρ = ASTRA.Microphysics.nuclear_density_derivative(
        screened,
        150.0,
        1.5e7,
        composition,
    )

    @test isfinite(dεdT)
    @test isfinite(dεdρ)
    @test isfinite(screened_dεdT)
    @test isfinite(screened_dεdρ)
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
    screened_fd_temperature =
        (
            screened(150.0, 1.5e7 + 1.0, composition).energy_rate_erg_g_s -
            screened(150.0, 1.5e7 - 1.0, composition).energy_rate_erg_g_s
        ) / 2.0
    screened_fd_density =
        (
            screened(150.0 + 1.0e-6, 1.5e7, composition).energy_rate_erg_g_s -
            screened(150.0 - 1.0e-6, 1.5e7, composition).energy_rate_erg_g_s
        ) / (2.0e-6)
    @test isapprox(dεdT, fd_temperature; rtol = 1.0e-4, atol = 1.0e-8)
    @test isapprox(dεdρ, fd_density; rtol = 1.0e-4, atol = 1.0e-8)
    @test isapprox(screened_dεdT, screened_fd_temperature; rtol = 1.0e-4, atol = 1.0e-8)
    @test isapprox(screened_dεdρ, screened_fd_density; rtol = 1.0e-4, atol = 1.0e-8)
end
