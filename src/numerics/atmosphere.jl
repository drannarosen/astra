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

"""
    outer_match_optical_depth(problem, model)

Return the one-sided outer-cell optical depth used for the Phase 2 atmosphere
match point.
"""
function outer_match_optical_depth(problem::StructureProblem, model::StellarModel)
    n = problem.grid.n_cells
    radius_surface_cm = exp(model.structure.log_radius_face_cm[end])
    opacity_outer_cm2_g = cell_opacity_state(problem, model, n).opacity_cm2_g
    sigma_half_g_cm2 =
        outer_half_cell_column_density_g_cm2(problem.grid.dm_cell_g[end], radius_surface_cm)
    return 2.0 / 3.0 + outer_half_cell_optical_depth(opacity_outer_cm2_g, sigma_half_g_cm2)
end

"""
    outer_match_temperature_k(problem, model)

Return the Eddington `T(τ)` temperature at ASTRA's one-sided outer-cell match
point.
"""
function outer_match_temperature_k(problem::StructureProblem, model::StellarModel)
    radius_surface_cm = exp(model.structure.log_radius_face_cm[end])
    luminosity_surface_erg_s = model.structure.luminosity_face_erg_s[end]
    teff_k = surface_effective_temperature_k(radius_surface_cm, luminosity_surface_erg_s)
    return eddington_t_tau_temperature_k(teff_k, outer_match_optical_depth(problem, model))
end

"""
    outer_match_pressure_dyn_cm2(problem, model)

Return the one-sided hydrostatic pressure target at ASTRA's outer-cell match
point.
"""
function outer_match_pressure_dyn_cm2(problem::StructureProblem, model::StellarModel)
    radius_surface_cm = exp(model.structure.log_radius_face_cm[end])
    n = problem.grid.n_cells
    opacity_outer_cm2_g = cell_opacity_state(problem, model, n).opacity_cm2_g
    g_surface_cgs = surface_gravity_cgs(problem.parameters.mass_g, radius_surface_cm)
    p_ph = eddington_photospheric_pressure_dyn_cm2(g_surface_cgs, opacity_outer_cm2_g)
    sigma_half_g_cm2 =
        outer_half_cell_column_density_g_cm2(problem.grid.dm_cell_g[end], radius_surface_cm)
    return p_ph + clip_positive(g_surface_cgs) * sigma_half_g_cm2
end
