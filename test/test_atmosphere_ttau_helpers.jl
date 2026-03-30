using Test
using ASTRA

@testset "T(tau) helpers" begin
    teff_k = ASTRA.SOLAR_EFFECTIVE_TEMPERATURE_K
    tau_ph = 2.0 / 3.0
    tau_deeper = tau_ph + 0.25

    t_ph = ASTRA.eddington_t_tau_temperature_k(teff_k, tau_ph)
    t_deeper = ASTRA.eddington_t_tau_temperature_k(teff_k, tau_deeper)

    @test t_ph ≈ teff_k rtol = 1e-12
    @test t_deeper > t_ph

    dm_half_g = 1.0e29
    radius_cm = ASTRA.SOLAR_RADIUS_CM
    opacity_cm2_g = 0.34
    sigma_half = ASTRA.outer_half_cell_column_density_g_cm2(dm_half_g, radius_cm)
    delta_tau = ASTRA.outer_half_cell_optical_depth(opacity_cm2_g, sigma_half)

    @test sigma_half > 0.0
    @test delta_tau > 0.0
end
