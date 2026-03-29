function assemble_structure_residual(problem::StructureProblem, state::StellarState)
    reference = toy_reference_state(problem)
    n = problem.grid.n_cells
    residual = Vector{Float64}(undef, 4 * n + 2)
    index = 1

    center = center_boundary_residual(problem, state)
    residual[index:(index + 1)] = center
    index += 2

    for k in 1:(n - 1)
        residual[index] = state.log_radius_face_cm[k + 1] - reference.log_radius_face_cm[k + 1]
        residual[index + 1] =
            state.luminosity_face_erg_s[k + 1] - reference.luminosity_face_erg_s[k + 1]
        residual[index + 2] =
            state.log_temperature_cell_k[k] - reference.log_temperature_cell_k[k]
        residual[index + 3] =
            state.log_density_cell_g_cm3[k] - reference.log_density_cell_g_cm3[k]
        index += 4
    end

    surface = surface_boundary_residual(problem, state)
    residual[index:(index + 3)] = surface
    return residual
end
