const SURFACE_DENSITY_GUESS_G_CM3 = 1.0e-7

function center_boundary_residual(problem::StructureProblem, model::StellarModel)
    state = model.structure
    r_inner_cm = exp(state.log_radius_face_cm[1])
    r_outer_cm = exp(state.log_radius_face_cm[2])
    density_g_cm3 = exp(state.log_density_cell_g_cm3[1])
    dm_1_g = problem.grid.dm_cell_g[1]

    return Float64[
        shell_volume_cm3(r_inner_cm, r_outer_cm) - dm_1_g / clip_positive(density_g_cm3),
        state.luminosity_face_erg_s[1],
    ]
end

function surface_boundary_residual(problem::StructureProblem, model::StellarModel)
    state = model.structure
    n = problem.grid.n_cells
    radius_surface_cm = exp(state.log_radius_face_cm[end])
    temperature_surface_k = exp(state.log_temperature_cell_k[n])
    density_surface_g_cm3 = exp(state.log_density_cell_g_cm3[n])

    return Float64[
        radius_surface_cm - problem.parameters.radius_guess_cm,
        state.luminosity_face_erg_s[end] - problem.parameters.luminosity_guess_erg_s,
        temperature_surface_k - problem.parameters.surface_temperature_guess_k,
        density_surface_g_cm3 - SURFACE_DENSITY_GUESS_G_CM3,
    ]
end
