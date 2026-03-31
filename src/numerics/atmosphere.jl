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

Return the photospheric-face temperature target at ASTRA's Eddington
photosphere.
"""
function outer_match_temperature_k(problem::StructureProblem, model::StellarModel)
    radius_surface_cm = exp(model.structure.log_radius_face_cm[end])
    luminosity_surface_erg_s = model.structure.luminosity_face_erg_s[end]
    return surface_effective_temperature_k(radius_surface_cm, luminosity_surface_erg_s)
end

function _photospheric_face_pressure_target_dyn_cm2(
    problem::StructureProblem,
    model::StellarModel,
)
    radius_surface_cm = exp(model.structure.log_radius_face_cm[end])
    n = problem.grid.n_cells
    opacity_outer_cm2_g = cell_opacity_state(problem, model, n).opacity_cm2_g
    g_surface_cgs = surface_gravity_cgs(problem.parameters.mass_g, radius_surface_cm)
    return eddington_photospheric_pressure_dyn_cm2(g_surface_cgs, opacity_outer_cm2_g)
end

function _bridge_pressure_target_dyn_cm2(problem::StructureProblem, model::StellarModel)
    radius_surface_cm = exp(model.structure.log_radius_face_cm[end])
    photospheric_face_pressure_dyn_cm2 =
        _photospheric_face_pressure_target_dyn_cm2(problem, model)
    g_surface_cgs = surface_gravity_cgs(problem.parameters.mass_g, radius_surface_cm)
    sigma_half_g_cm2 =
        outer_half_cell_column_density_g_cm2(problem.grid.dm_cell_g[end], radius_surface_cm)
    return photospheric_face_pressure_dyn_cm2 + clip_positive(g_surface_cgs) * sigma_half_g_cm2
end

function _selected_pressure_target_dyn_cm2(problem::StructureProblem, model::StellarModel)
    mode = problem.solver.pressure_closure_mode
    mode == :bridge && return _bridge_pressure_target_dyn_cm2(problem, model)
    mode == :photosphere_control &&
        return _photospheric_face_pressure_target_dyn_cm2(problem, model)
    throw(ArgumentError("Unsupported pressure_closure_mode $(mode)."))
end

"""
    outer_match_pressure_dyn_cm2(problem, model)

Return the one-sided hydrostatic pressure target at ASTRA's outer-cell match
point.
"""
function outer_match_pressure_dyn_cm2(problem::StructureProblem, model::StellarModel)
    return _bridge_pressure_target_dyn_cm2(problem, model)
end

"""
    outer_boundary_fitting_point_terms(problem, model)

Return diagnostic-only outer-boundary terms that compare the current match
point against the photospheric fitting point.
"""
function outer_boundary_fitting_point_terms(problem::StructureProblem, model::StellarModel)
    n = problem.grid.n_cells
    state = model.structure
    radius_surface_cm = exp(state.log_radius_face_cm[end])
    luminosity_surface_erg_s = state.luminosity_face_erg_s[end]
    pressure_surface_dyn_cm2 = cell_eos_state(problem, model, n).pressure_dyn_cm2
    temperature_surface_k = exp(state.log_temperature_cell_k[n])

    photospheric_face_temperature_k = surface_effective_temperature_k(
        radius_surface_cm,
        luminosity_surface_erg_s,
    )
    opacity_outer_cm2_g = cell_opacity_state(problem, model, n).opacity_cm2_g
    g_surface_cgs = surface_gravity_cgs(problem.parameters.mass_g, radius_surface_cm)
    photospheric_face_pressure_dyn_cm2 = eddington_photospheric_pressure_dyn_cm2(
        g_surface_cgs,
        opacity_outer_cm2_g,
    )
    half_cell_column_density_g_cm2 = outer_half_cell_column_density_g_cm2(
        problem.grid.dm_cell_g[end],
        radius_surface_cm,
    )
    half_cell_optical_depth = outer_half_cell_optical_depth(
        opacity_outer_cm2_g,
        half_cell_column_density_g_cm2,
    )
    hydrostatic_pressure_offset_dyn_cm2 = g_surface_cgs * half_cell_column_density_g_cm2
    outer_terms = transport_row_terms(problem, model, n - 1)
    transport_nabla_outer = outer_terms.nabla_transport
    transport_temperature_offset_k =
        hydrostatic_pressure_offset_dyn_cm2 *
        transport_nabla_outer *
        temperature_surface_k /
        pressure_surface_dyn_cm2
    current_match_temperature_k = outer_match_temperature_k(problem, model)
    current_match_pressure_dyn_cm2 = _selected_pressure_target_dyn_cm2(problem, model)
    fitting_point_temperature_k =
        photospheric_face_temperature_k + transport_temperature_offset_k
    fitting_point_pressure_dyn_cm2 =
        photospheric_face_pressure_dyn_cm2 + hydrostatic_pressure_offset_dyn_cm2

    return OuterBoundaryFittingPointTerms(
        photospheric_face_temperature_k,
        photospheric_face_pressure_dyn_cm2,
        half_cell_column_density_g_cm2,
        half_cell_optical_depth,
        hydrostatic_pressure_offset_dyn_cm2,
        transport_nabla_outer,
        transport_temperature_offset_k,
        current_match_temperature_k,
        current_match_pressure_dyn_cm2,
        fitting_point_temperature_k,
        fitting_point_pressure_dyn_cm2,
        positive_log(current_match_temperature_k) - positive_log(fitting_point_temperature_k),
        positive_log(current_match_pressure_dyn_cm2) - positive_log(fitting_point_pressure_dyn_cm2),
    )
end

"""
    surface_temperature_semantics(problem, model)

Return the diagnostic decomposition of the live surface-temperature row into
the photospheric reference, the match point, and the derived log gaps.
"""
function surface_temperature_semantics(problem::StructureProblem, model::StellarModel)
    n = problem.grid.n_cells
    state = model.structure
    surface_temperature_k = exp(state.log_temperature_cell_k[n])
    radius_surface_cm = exp(state.log_radius_face_cm[end])
    luminosity_surface_erg_s = state.luminosity_face_erg_s[end]
    photospheric_face_temperature_k = surface_effective_temperature_k(
        radius_surface_cm,
        luminosity_surface_erg_s,
    )
    fitting_point_terms = outer_boundary_fitting_point_terms(problem, model)
    match_temperature_k = fitting_point_terms.current_match_temperature_k
    transport_temperature_offset_k = fitting_point_terms.transport_temperature_offset_k
    surface_to_photosphere_log_gap =
        positive_log(surface_temperature_k) - positive_log(photospheric_face_temperature_k)
    match_to_photosphere_log_gap =
        positive_log(match_temperature_k) - positive_log(photospheric_face_temperature_k)
    surface_to_match_log_gap =
        positive_log(surface_temperature_k) - positive_log(match_temperature_k)
    transport_temperature_offset_fraction =
        transport_temperature_offset_k / photospheric_face_temperature_k

    return SurfaceTemperatureSemantics(
        surface_temperature_k,
        photospheric_face_temperature_k,
        match_temperature_k,
        transport_temperature_offset_k,
        surface_to_photosphere_log_gap,
        match_to_photosphere_log_gap,
        surface_to_match_log_gap,
        transport_temperature_offset_fraction,
    )
end

"""
    surface_pressure_semantics(problem, model)

Return the diagnostic decomposition of the live surface-pressure row into the
photospheric pressure reference, the deeper match point, and the derived log
gaps.
"""
function surface_pressure_semantics(problem::StructureProblem, model::StellarModel)
    n = problem.grid.n_cells
    state = model.structure
    radius_surface_cm = exp(state.log_radius_face_cm[end])
    opacity_outer_cm2_g = cell_opacity_state(problem, model, n).opacity_cm2_g
    g_surface_cgs = surface_gravity_cgs(problem.parameters.mass_g, radius_surface_cm)
    photospheric_face_pressure_dyn_cm2 =
        eddington_photospheric_pressure_dyn_cm2(g_surface_cgs, opacity_outer_cm2_g)

    fitting_point_terms = outer_boundary_fitting_point_terms(problem, model)
    surface_pressure_dyn_cm2 = cell_eos_state(problem, model, n).pressure_dyn_cm2
    match_pressure_dyn_cm2 = fitting_point_terms.current_match_pressure_dyn_cm2
    hydrostatic_pressure_offset_dyn_cm2 = fitting_point_terms.hydrostatic_pressure_offset_dyn_cm2

    surface_to_photosphere_log_gap =
        positive_log(surface_pressure_dyn_cm2) - positive_log(photospheric_face_pressure_dyn_cm2)
    match_to_photosphere_log_gap =
        positive_log(match_pressure_dyn_cm2) - positive_log(photospheric_face_pressure_dyn_cm2)
    surface_to_match_log_gap =
        positive_log(surface_pressure_dyn_cm2) - positive_log(match_pressure_dyn_cm2)
    hydrostatic_pressure_offset_fraction =
        hydrostatic_pressure_offset_dyn_cm2 / photospheric_face_pressure_dyn_cm2

    return SurfacePressureSemantics(
        surface_pressure_dyn_cm2,
        photospheric_face_pressure_dyn_cm2,
        match_pressure_dyn_cm2,
        hydrostatic_pressure_offset_dyn_cm2,
        surface_to_photosphere_log_gap,
        match_to_photosphere_log_gap,
        surface_to_match_log_gap,
        hydrostatic_pressure_offset_fraction,
    )
end
