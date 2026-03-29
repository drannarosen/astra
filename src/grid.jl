"""
    build_grid(parameters, config)

Construct a monotonic mass grid in the enclosed-mass coordinate.
"""
function build_grid(parameters::StellarParameters, config::GridConfig)
    m_inner = parameters.mass_g * config.inner_mass_fraction
    m_face = collect(range(m_inner, parameters.mass_g; length = config.n_cells + 1))
    dm_cell = diff(m_face)
    return StellarGrid(m_face, dm_cell, config.n_cells)
end
