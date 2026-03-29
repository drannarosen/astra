function summarize_state(state::StellarState)
    return (
        radius_cm = exp(state.log_radius_face_cm[end]),
        luminosity_erg_s = state.luminosity_face_erg_s[end],
        center_temperature_k = exp(state.log_temperature_cell_k[1]),
        center_density_g_cm3 = exp(state.log_density_cell_g_cm3[1]),
        n_cells = state.grid.n_cells,
    )
end

function Base.show(io::IO, state::StellarState)
    summary = summarize_state(state)
    print(
        io,
        "StellarState(n_cells=$(summary.n_cells), ",
        "R=$(summary.radius_cm) cm, ",
        "L=$(summary.luminosity_erg_s) erg/s)",
    )
end
