const STEFAN_BOLTZMANN_CONSTANT_CGS = RADIATION_CONSTANT_CGS * SPEED_OF_LIGHT_CGS / 4.0

"""
    surface_effective_temperature_k(radius_cm, luminosity_erg_s)

Return the effective temperature implied by the Stefan-Boltzmann law using
ASTRA's cgs structure state.
"""
function surface_effective_temperature_k(radius_cm::Real, luminosity_erg_s::Real)
    radius_value = clip_positive(radius_cm)
    luminosity_value = clip_positive(luminosity_erg_s)
    return (luminosity_value / (4.0 * π * STEFAN_BOLTZMANN_CONSTANT_CGS * radius_value^2))^(1.0 / 4.0)
end

"""
    surface_gravity_cgs(mass_g, radius_cm)

Return the surface gravity in cgs units for the current outer face.
"""
function surface_gravity_cgs(mass_g::Real, radius_cm::Real)
    return GRAVITATIONAL_CONSTANT_CGS * clip_positive(mass_g) / clip_positive(radius_cm)^2
end

"""
    eddington_photospheric_pressure_dyn_cm2(g_surface_cgs, opacity_cm2_g)

Return the Eddington-grey photospheric pressure target at optical depth 2/3.
"""
function eddington_photospheric_pressure_dyn_cm2(g_surface_cgs::Real, opacity_cm2_g::Real)
    return (2.0 / 3.0) * clip_positive(g_surface_cgs) / clip_positive(opacity_cm2_g)
end
