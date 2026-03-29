function interior_structure_block(problem::StructureProblem, model::StellarModel, k::Int)
    state = model.structure
    r_left_cm = exp(state.log_radius_face_cm[k])
    r_right_cm = exp(state.log_radius_face_cm[k + 1])
    density_k_g_cm3 = exp(state.log_density_cell_g_cm3[k])
    pressure_k_dyn_cm2 = cell_eos_state(problem, model, k).pressure_dyn_cm2
    pressure_kp1_dyn_cm2 = cell_eos_state(problem, model, k + 1).pressure_dyn_cm2
    energy_rate_k_erg_g_s = cell_nuclear_state(problem, model, k).energy_rate_erg_g_s
    nabla_transport = radiative_temperature_gradient(problem, model, k)
    dm_g = problem.grid.dm_cell_g[k]
    enclosed_mass_g = problem.grid.m_face_g[k + 1]

    geometry =
        shell_volume_cm3(r_left_cm, r_right_cm) - dm_g / clip_positive(density_k_g_cm3)
    hydrostatic =
        pressure_kp1_dyn_cm2 - pressure_k_dyn_cm2 +
        GRAVITATIONAL_CONSTANT_CGS * clip_positive(enclosed_mass_g) * dm_g /
        (4.0 * π * clip_positive(r_right_cm)^4)
    luminosity =
        state.luminosity_face_erg_s[k + 1] - state.luminosity_face_erg_s[k] - dm_g * energy_rate_k_erg_g_s
    transport =
        state.log_temperature_cell_k[k + 1] - state.log_temperature_cell_k[k] +
        nabla_transport *
        (log(clip_positive(pressure_kp1_dyn_cm2)) - log(clip_positive(pressure_k_dyn_cm2)))

    return Float64[geometry, hydrostatic, luminosity, transport]
end

function assemble_structure_residual(problem::StructureProblem, model::StellarModel)
    n = problem.grid.n_cells
    residual = Vector{Float64}(undef, 4 * n + 2)
    index = 1

    center = center_boundary_residual(problem, model)
    residual[index:(index + 1)] = center
    index += 2

    for k in 1:(n - 1)
        residual[index:(index + 3)] = interior_structure_block(problem, model, k)
        index += 4
    end

    surface = surface_boundary_residual(problem, model)
    residual[index:(index + 3)] = surface
    return residual
end
