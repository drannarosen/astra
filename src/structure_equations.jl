"""
    shell_volume_cm3(r_inner_cm, r_outer_cm)

Return the spherical shell volume between two radii in cgs units.
"""
shell_volume_cm3(r_inner_cm::Real, r_outer_cm::Real) =
    (4.0 * π / 3.0) * (Float64(r_outer_cm)^3 - Float64(r_inner_cm)^3)

"""
    cell_composition(problem, model, k)

Return the bulk composition stored for cell `k`.
"""
function cell_composition(problem::StructureProblem, model::StellarModel, k::Int)
    return Composition(
        model.composition.hydrogen_mass_fraction_cell[k],
        model.composition.helium_mass_fraction_cell[k],
        model.composition.metal_mass_fraction_cell[k],
    )
end

"""
    cell_eos_state(problem, model, k)

Evaluate the EOS closure for cell `k` using the current structure state.
"""
function cell_eos_state(problem::StructureProblem, model::StellarModel, k::Int)
    density_g_cm3 = exp(model.structure.log_density_cell_g_cm3[k])
    temperature_k = exp(model.structure.log_temperature_cell_k[k])
    return problem.microphysics.eos(density_g_cm3, temperature_k, cell_composition(problem, model, k))
end

"""
    cell_opacity_state(problem, model, k)

Evaluate the opacity closure for cell `k` using the current structure state.
"""
function cell_opacity_state(problem::StructureProblem, model::StellarModel, k::Int)
    density_g_cm3 = exp(model.structure.log_density_cell_g_cm3[k])
    temperature_k = exp(model.structure.log_temperature_cell_k[k])
    return problem.microphysics.opacity(
        density_g_cm3,
        temperature_k,
        cell_composition(problem, model, k),
    )
end

"""
    cell_nuclear_state(problem, model, k)

Evaluate the nuclear-heating closure for cell `k` using the current structure state.
"""
function cell_nuclear_state(problem::StructureProblem, model::StellarModel, k::Int)
    density_g_cm3 = exp(model.structure.log_density_cell_g_cm3[k])
    temperature_k = exp(model.structure.log_temperature_cell_k[k])
    return problem.microphysics.nuclear(
        density_g_cm3,
        temperature_k,
        cell_composition(problem, model, k),
    )
end

"""
    radiative_temperature_gradient(problem, model, k)

Return the provisional radiative temperature gradient used by the first
classical residual slice.
"""
function radiative_temperature_gradient(problem::StructureProblem, model::StellarModel, k::Int)
    eos_state = cell_eos_state(problem, model, k)
    opacity_state = cell_opacity_state(problem, model, k)
    luminosity_erg_s = model.structure.luminosity_face_erg_s[k + 1]
    pressure_dyn_cm2 = eos_state.pressure_dyn_cm2
    temperature_k = exp(model.structure.log_temperature_cell_k[k])
    enclosed_mass_g = problem.grid.m_face_g[k + 1]

    return (
        3.0 * opacity_state.opacity_cm2_g * luminosity_erg_s * pressure_dyn_cm2 /
        (
            16.0 *
            π *
            RADIATION_CONSTANT_CGS *
            SPEED_OF_LIGHT_CGS *
            GRAVITATIONAL_CONSTANT_CGS *
            clip_positive(enclosed_mass_g) *
            temperature_k^4
        )
    )
end
