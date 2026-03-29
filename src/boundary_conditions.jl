function center_boundary_residual(problem::StructureProblem, state::StellarState)
    reference = toy_reference_state(problem)
    return Float64[
        state.log_radius_face_cm[1] - reference.log_radius_face_cm[1],
        state.luminosity_face_erg_s[1] - reference.luminosity_face_erg_s[1],
    ]
end

function surface_boundary_residual(problem::StructureProblem, state::StellarState)
    reference = toy_reference_state(problem)
    n = problem.grid.n_cells
    return Float64[
        state.log_radius_face_cm[end] - reference.log_radius_face_cm[end],
        state.luminosity_face_erg_s[end] - reference.luminosity_face_erg_s[end],
        state.log_temperature_cell_k[n] - reference.log_temperature_cell_k[n],
        state.log_density_cell_g_cm3[n] - reference.log_density_cell_g_cm3[n],
    ]
end
