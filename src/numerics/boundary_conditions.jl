const SURFACE_DENSITY_GUESS_G_CM3 = 1.0e-7

function center_radius_series_target_cm(problem::StructureProblem, model::StellarModel)
    density_g_cm3 = exp(model.structure.log_density_cell_g_cm3[1])
    enclosed_mass_g = problem.grid.m_face_g[1]
    return (3.0 * enclosed_mass_g / (4.0 * π * clip_positive(density_g_cm3)))^(1.0 / 3.0)
end

function center_luminosity_series_target_erg_s(problem::StructureProblem, model::StellarModel)
    return problem.grid.m_face_g[1] * cell_energy_source_state(problem, model, 1).eps_total_erg_g_s
end

function center_boundary_residual(problem::StructureProblem, model::StellarModel)
    state = model.structure
    r_inner_cm = exp(state.log_radius_face_cm[1])

    return Float64[
        r_inner_cm - center_radius_series_target_cm(problem, model),
        state.luminosity_face_erg_s[1] - center_luminosity_series_target_erg_s(problem, model),
    ]
end

function surface_boundary_residual(problem::StructureProblem, model::StellarModel)
    state = model.structure
    n = problem.grid.n_cells
    radius_surface_cm = exp(state.log_radius_face_cm[end])
    temperature_surface_k = exp(state.log_temperature_cell_k[n])
    luminosity_surface_erg_s = state.luminosity_face_erg_s[end]
    pressure_surface_dyn_cm2 = cell_eos_state(problem, model, n).pressure_dyn_cm2
    temperature_match_k = outer_match_temperature_k(problem, model)
    pressure_match_dyn_cm2 = outer_match_pressure_dyn_cm2(problem, model)

    return Float64[
        radius_surface_cm - problem.parameters.radius_guess_cm,
        luminosity_surface_erg_s - problem.parameters.luminosity_guess_erg_s,
        positive_log(temperature_surface_k) - positive_log(temperature_match_k),
        pressure_surface_dyn_cm2 - pressure_match_dyn_cm2,
    ]
end
