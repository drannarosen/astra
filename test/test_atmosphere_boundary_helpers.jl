@testset "atmosphere boundary helpers" begin
    radius_cm = ASTRA.SOLAR_RADIUS_CM
    luminosity_erg_s = ASTRA.SOLAR_LUMINOSITY_ERG_S
    mass_g = ASTRA.SOLAR_MASS_G
    opacity_cm2_g = 0.34

    teff_k = ASTRA.surface_effective_temperature_k(radius_cm, luminosity_erg_s)
    g_surface_cgs = ASTRA.surface_gravity_cgs(mass_g, radius_cm)
    p_ph_dyn_cm2 = ASTRA.eddington_photospheric_pressure_dyn_cm2(g_surface_cgs, opacity_cm2_g)

    @test teff_k ≈ ASTRA.SOLAR_EFFECTIVE_TEMPERATURE_K rtol = 5.0e-3
    @test g_surface_cgs > 0.0
    @test p_ph_dyn_cm2 ≈ (2.0 / 3.0) * g_surface_cgs / opacity_cm2_g rtol = 1.0e-12
end
