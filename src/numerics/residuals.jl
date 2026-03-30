structure_center_row_range() = 1:2

interior_structure_row_range(k::Int) = (3 + 4 * (k - 1)):(6 + 4 * (k - 1))

function structure_surface_row_range(n_cells::Int)
    start = 4 * n_cells - 1
    return start:(start + 3)
end

function interior_structure_block(problem::StructureProblem, model::StellarModel, k::Int)
    state = model.structure
    r_left_cm = exp(state.log_radius_face_cm[k])
    r_right_cm = exp(state.log_radius_face_cm[k + 1])
    density_k_g_cm3 = exp(state.log_density_cell_g_cm3[k])
    pressure_k_dyn_cm2 = cell_eos_state(problem, model, k).pressure_dyn_cm2
    pressure_kp1_dyn_cm2 = cell_eos_state(problem, model, k + 1).pressure_dyn_cm2
    energy_rate_k_erg_g_s = cell_energy_source_state(problem, model, k).eps_total_erg_g_s
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
    residual[structure_center_row_range()] = center
    index = last(structure_center_row_range()) + 1

    for k in 1:(n - 1)
        row_range = interior_structure_row_range(k)
        residual[row_range] = interior_structure_block(problem, model, k)
        index = last(row_range) + 1
    end

    surface = surface_boundary_residual(problem, model)
    residual[structure_surface_row_range(n)] = surface
    return residual
end
