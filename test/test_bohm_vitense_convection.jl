@testset "Bohm-Vitense convection closure" begin
    closure = ASTRA.Microphysics.BohmVitenseMLTConvection(1.8)

    stable = ASTRA.Microphysics.ConvectionLocalState(
        1.0e10,
        1.0e33,
        1.0e33,
        1.0e17,
        1.0e7,
        10.0,
        0.2,
        3.0e8,
        1.0,
        0.25,
        0.4,
        0.2,
        0.0,
    )
    convective = ASTRA.Microphysics.ConvectionLocalState(
        stable.radius_cm,
        stable.enclosed_mass_g,
        stable.luminosity_erg_s,
        stable.pressure_dyn_cm2,
        stable.temperature_k,
        stable.density_g_cm3,
        stable.opacity_cm2_g,
        stable.specific_heat_erg_g_k,
        stable.chi_rho,
        stable.chi_T,
        stable.adiabatic_gradient,
        0.8,
        stable.ledoux_composition_term,
    )

    stable_result = closure(stable)
    convective_result = closure(convective)

    @test stable_result.transport_regime == :radiative
    @test stable_result.active_gradient ≈ stable.radiative_gradient
    @test stable_result.convective_velocity_cm_s == 0.0
    @test convective_result.transport_regime == :convective
    @test convective_result.adiabatic_gradient <= convective_result.active_gradient <=
          convective_result.radiative_gradient
    @test convective_result.superadiabatic_excess >= 0.0
    @test convective_result.convective_velocity_cm_s > 0.0
    @test 0.0 <= convective_result.convective_flux_fraction <= 1.0
end
