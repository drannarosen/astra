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

"""
    eddington_t_tau_temperature_k(teff_k, tau)

Return the Eddington-grey temperature at optical depth `tau`.
"""
function eddington_t_tau_temperature_k(teff_k::Real, tau::Real)
    teff_value = clip_positive(teff_k)
    tau_value = clip_positive(tau)
    return teff_value * ((3.0 / 4.0) * (tau_value + 2.0 / 3.0))^(1.0 / 4.0)
end

"""
    outer_half_cell_column_density_g_cm2(dm_cell_g, radius_surface_cm)

Return the approximate surface-half-cell column mass in g/cm^2.
"""
function outer_half_cell_column_density_g_cm2(dm_cell_g::Real, radius_surface_cm::Real)
    dm_value = clip_positive(dm_cell_g)
    radius_value = clip_positive(radius_surface_cm)
    return dm_value / (8.0 * π * radius_value^2)
end

"""
    outer_half_cell_optical_depth(opacity_cm2_g, sigma_half_g_cm2)

Return the optical-depth increment across the outer half-cell.
"""
function outer_half_cell_optical_depth(opacity_cm2_g::Real, sigma_half_g_cm2::Real)
    return clip_positive(opacity_cm2_g) * clip_positive(sigma_half_g_cm2)
end
