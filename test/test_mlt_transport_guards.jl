@testset "MLT transport guards" begin
    closure = ASTRA.Microphysics.BohmVitenseMLTConvection(1.8)

    base = ASTRA.Microphysics.ConvectionLocalState(
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
        0.8,
        0.0,
    )

    bad_opacity = ASTRA.Microphysics.ConvectionLocalState(
        base.radius_cm,
        base.enclosed_mass_g,
        base.luminosity_erg_s,
        base.pressure_dyn_cm2,
        base.temperature_k,
        base.density_g_cm3,
        0.0,
        base.specific_heat_erg_g_k,
        base.chi_rho,
        base.chi_T,
        base.adiabatic_gradient,
        base.radiative_gradient,
        base.ledoux_composition_term,
    )
    bad_chirho = ASTRA.Microphysics.ConvectionLocalState(
        base.radius_cm,
        base.enclosed_mass_g,
        base.luminosity_erg_s,
        base.pressure_dyn_cm2,
        base.temperature_k,
        base.density_g_cm3,
        base.opacity_cm2_g,
        base.specific_heat_erg_g_k,
        0.0,
        base.chi_T,
        base.adiabatic_gradient,
        base.radiative_gradient,
        base.ledoux_composition_term,
    )
    bad_radius = ASTRA.Microphysics.ConvectionLocalState(
        0.0,
        base.enclosed_mass_g,
        base.luminosity_erg_s,
        base.pressure_dyn_cm2,
        base.temperature_k,
        base.density_g_cm3,
        base.opacity_cm2_g,
        base.specific_heat_erg_g_k,
        base.chi_rho,
        base.chi_T,
        base.adiabatic_gradient,
        base.radiative_gradient,
        base.ledoux_composition_term,
    )

    for local_state in (bad_opacity, bad_chirho, bad_radius)
        result = closure(local_state)
        @test result.transport_regime == :radiative
        @test result.guarded
        @test result.active_gradient ≈ result.radiative_gradient
        @test result.convective_velocity_cm_s == 0.0
        @test result.convective_flux_fraction == 0.0
    end

    good = closure(base)
    @test !good.guarded
    @test 0.0 <= good.convective_flux_fraction <= 1.0
    @test good.ledoux_gradient <= good.active_gradient <= good.radiative_gradient
end
