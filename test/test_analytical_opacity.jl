@testset "analytical opacity" begin
    composition = Composition(0.70, 0.28, 0.02)
    κ_model = ASTRA.Microphysics.AnalyticalOpacity()

    hot = κ_model(1.0, 1.5e7, composition)
    cool = κ_model(1.0e-8, 6000.0, composition)

    @test hot.opacity_cm2_g > 0.0
    @test cool.opacity_cm2_g > 0.0
    @test cool.opacity_cm2_g != hot.opacity_cm2_g
    @test hot.source == :analytical_opacity

    dκdT = ASTRA.Microphysics.opacity_temperature_derivative(
        κ_model,
        1.0,
        1.5e7,
        composition,
    )
    dκdρ = ASTRA.Microphysics.opacity_density_derivative(
        κ_model,
        1.0,
        1.5e7,
        composition,
    )
    dκdρ_low = ASTRA.Microphysics.opacity_density_derivative(
        κ_model,
        1.0e-8,
        6000.0,
        composition,
    )

    @test isfinite(dκdT)
    @test isfinite(dκdρ)

    dκdρ_fd =
        (
            κ_model(1.0e-8 + 1.0e-12, 6000.0, composition).opacity_cm2_g -
            κ_model(1.0e-8 - 1.0e-12, 6000.0, composition).opacity_cm2_g
        ) / (2.0e-12)
    @test isfinite(dκdρ_fd)
    @test isapprox(dκdρ_low, dκdρ_fd; rtol = 1.0e-3, atol = 1.0e-6)

    cold = κ_model(1.0, 1.0, composition)
    cold_dκdT = ASTRA.Microphysics.opacity_temperature_derivative(
        κ_model,
        1.0,
        1.0,
        composition,
    )
    @test isfinite(cold.opacity_cm2_g)
    @test isfinite(cold_dκdT)

    fd =
        (
            κ_model(1.0, 1.5e7 + 1.0, composition).opacity_cm2_g -
            κ_model(1.0, 1.5e7 - 1.0, composition).opacity_cm2_g
        ) / 2.0
    @test isapprox(dκdT, fd; rtol = 1.0e-4, atol = 1.0e-8)
end
