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
    cell_energy_source_state(problem, model, k)

Evaluate the assembled analytical source terms for cell `k`.
"""
function cell_energy_source_state(problem::StructureProblem, model::StellarModel, k::Int)
    return energy_source_terms(problem, model, k)
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

"""
    transport_row_terms(problem, model, k)

Return the canonical transport-row decomposition for cell `k`, including the
temperature term, the gradient term, and the assembled residual contribution.
The final interior row uses the one-sided outer face pressure target selected by
the internal solver control.
"""
function _selected_outer_transport_pressure_target_dyn_cm2(
    problem::StructureProblem,
    model::StellarModel,
)
    mode = problem.solver.outer_transport_pressure_mode
    mode == :photospheric_face &&
        return _photospheric_outer_transport_pressure_target_dyn_cm2(problem, model)
    mode == :selected_pressure_target &&
        return _selected_pressure_target_dyn_cm2(problem, model)
    throw(ArgumentError("Unsupported outer_transport_pressure_mode $(mode)."))
end

function transport_row_terms(problem::StructureProblem, model::StellarModel, k::Int)
    state = model.structure
    n = problem.grid.n_cells
    pressure_k_dyn_cm2 = cell_eos_state(problem, model, k).pressure_dyn_cm2
    nabla_transport = radiative_temperature_gradient(problem, model, k)
    is_outer = k == n - 1

    if is_outer
        radius_surface_cm = exp(state.log_radius_face_cm[end])
        luminosity_surface_erg_s = state.luminosity_face_erg_s[end]
        face_temperature_k = surface_effective_temperature_k(
            radius_surface_cm,
            luminosity_surface_erg_s,
        )
        transport_pressure_target_dyn_cm2 =
            _selected_outer_transport_pressure_target_dyn_cm2(problem, model)
        delta_log_temperature = positive_log(face_temperature_k) - state.log_temperature_cell_k[k]
        delta_log_pressure =
            log(clip_positive(transport_pressure_target_dyn_cm2)) -
            log(clip_positive(pressure_k_dyn_cm2))
        gradient_term = nabla_transport * delta_log_pressure
        return (
            cell_index = k,
            location = :outer,
            is_outer = true,
            delta_log_temperature = delta_log_temperature,
            delta_log_pressure = delta_log_pressure,
            nabla_transport = nabla_transport,
            gradient_term = gradient_term,
            transport_pressure_target_dyn_cm2 = transport_pressure_target_dyn_cm2,
            residual = delta_log_temperature - gradient_term,
        )
    end

    pressure_kp1_dyn_cm2 = cell_eos_state(problem, model, k + 1).pressure_dyn_cm2
    delta_log_temperature = state.log_temperature_cell_k[k + 1] - state.log_temperature_cell_k[k]
    delta_log_pressure =
        log(clip_positive(pressure_kp1_dyn_cm2)) - log(clip_positive(pressure_k_dyn_cm2))
    gradient_term = nabla_transport * delta_log_pressure
    return (
        cell_index = k,
        location = :interior,
        is_outer = false,
        delta_log_temperature = delta_log_temperature,
        delta_log_pressure = delta_log_pressure,
        nabla_transport = nabla_transport,
        gradient_term = gradient_term,
        residual = delta_log_temperature - gradient_term,
    )
end

function _photospheric_outer_transport_pressure_target_dyn_cm2(
    problem::StructureProblem,
    model::StellarModel,
)
    n = problem.grid.n_cells
    radius_surface_cm = exp(model.structure.log_radius_face_cm[end])
    opacity_outer_cm2_g = cell_opacity_state(problem, model, n).opacity_cm2_g
    g_surface_cgs = surface_gravity_cgs(problem.parameters.mass_g, radius_surface_cm)
    return eddington_photospheric_pressure_dyn_cm2(g_surface_cgs, opacity_outer_cm2_g)
end

function outer_transport_pressure_semantics(problem::StructureProblem, model::StellarModel)
    photospheric_face_pressure_dyn_cm2 =
        _photospheric_outer_transport_pressure_target_dyn_cm2(problem, model)
    selected_pressure_target_dyn_cm2 = _selected_pressure_target_dyn_cm2(problem, model)
    transport_pressure_target_dyn_cm2 =
        _photospheric_outer_transport_pressure_target_dyn_cm2(problem, model)
    return OuterTransportPressureSemantics(
        photospheric_face_pressure_dyn_cm2,
        selected_pressure_target_dyn_cm2,
        transport_pressure_target_dyn_cm2,
        positive_log(selected_pressure_target_dyn_cm2) -
        positive_log(transport_pressure_target_dyn_cm2),
    )
end

function _with_cell_temperature(
    model::StellarModel,
    k::Int,
    temperature_k::Real,
)
    structure = model.structure
    log_temperature_cell_k = copy(structure.log_temperature_cell_k)
    log_temperature_cell_k[k] = positive_log(temperature_k)
    next_structure = StructureState(
        structure.grid,
        copy(structure.log_radius_face_cm),
        copy(structure.luminosity_face_erg_s),
        log_temperature_cell_k,
        copy(structure.log_density_cell_g_cm3),
    )
    return StellarModel(next_structure, model.composition, model.evolution)
end

function _with_cell_density(
    model::StellarModel,
    k::Int,
    density_g_cm3::Real,
)
    structure = model.structure
    log_density_cell_g_cm3 = copy(structure.log_density_cell_g_cm3)
    log_density_cell_g_cm3[k] = positive_log(density_g_cm3)
    next_structure = StructureState(
        structure.grid,
        copy(structure.log_radius_face_cm),
        copy(structure.luminosity_face_erg_s),
        copy(structure.log_temperature_cell_k),
        log_density_cell_g_cm3,
    )
    return StellarModel(next_structure, model.composition, model.evolution)
end

function finite_difference_temperature_gradient_sensitivity(
    problem::StructureProblem,
    model::StellarModel,
    k::Int;
    relative_step::Real = 1.0e-6,
)
    temperature_k = exp(model.structure.log_temperature_cell_k[k])
    step_k = max(Float64(relative_step) * temperature_k, 1.0e-3)
    model_plus = _with_cell_temperature(model, k, temperature_k + step_k)
    model_minus = _with_cell_temperature(model, k, temperature_k - step_k)
    gradient_plus = radiative_temperature_gradient(problem, model_plus, k)
    gradient_minus = radiative_temperature_gradient(problem, model_minus, k)
    return (gradient_plus - gradient_minus) / (2.0 * step_k)
end

function finite_difference_density_gradient_sensitivity(
    problem::StructureProblem,
    model::StellarModel,
    k::Int;
    relative_step::Real = 1.0e-6,
)
    density_g_cm3 = exp(model.structure.log_density_cell_g_cm3[k])
    step_ρ = max(Float64(relative_step) * density_g_cm3, 1.0e-6)
    model_plus = _with_cell_density(model, k, density_g_cm3 + step_ρ)
    model_minus = _with_cell_density(model, k, density_g_cm3 - step_ρ)
    gradient_plus = radiative_temperature_gradient(problem, model_plus, k)
    gradient_minus = radiative_temperature_gradient(problem, model_minus, k)
    return (gradient_plus - gradient_minus) / (2.0 * step_ρ)
end

function helper_temperature_gradient_sensitivity(
    problem::StructureProblem,
    model::StellarModel,
    k::Int,
)
    density_g_cm3 = exp(model.structure.log_density_cell_g_cm3[k])
    temperature_k = exp(model.structure.log_temperature_cell_k[k])
    luminosity_erg_s = model.structure.luminosity_face_erg_s[k + 1]
    enclosed_mass_g = problem.grid.m_face_g[k + 1]
    composition = cell_composition(problem, model, k)
    eos_state = cell_eos_state(problem, model, k)
    opacity_state = cell_opacity_state(problem, model, k)
    dκ_dT = Microphysics.opacity_temperature_derivative(
        problem.microphysics.opacity,
        density_g_cm3,
        temperature_k,
        composition,
    )
    dP_dT = Microphysics.pressure_temperature_derivative(
        problem.microphysics.eos,
        density_g_cm3,
        temperature_k,
        composition,
    )
    prefactor =
        3.0 * luminosity_erg_s /
        (
            16.0 *
            π *
            RADIATION_CONSTANT_CGS *
            SPEED_OF_LIGHT_CGS *
            GRAVITATIONAL_CONSTANT_CGS *
            clip_positive(enclosed_mass_g) *
            temperature_k^4
        )
    thermal_term =
        dκ_dT * eos_state.pressure_dyn_cm2 +
        opacity_state.opacity_cm2_g * dP_dT -
        4.0 * opacity_state.opacity_cm2_g * eos_state.pressure_dyn_cm2 / clip_positive(temperature_k)
    return prefactor * thermal_term
end

function helper_density_gradient_sensitivity(
    problem::StructureProblem,
    model::StellarModel,
    k::Int,
)
    density_g_cm3 = exp(model.structure.log_density_cell_g_cm3[k])
    temperature_k = exp(model.structure.log_temperature_cell_k[k])
    luminosity_erg_s = model.structure.luminosity_face_erg_s[k + 1]
    enclosed_mass_g = problem.grid.m_face_g[k + 1]
    composition = cell_composition(problem, model, k)
    eos_state = cell_eos_state(problem, model, k)
    opacity_state = cell_opacity_state(problem, model, k)
    dκ_dρ = Microphysics.opacity_density_derivative(
        problem.microphysics.opacity,
        density_g_cm3,
        temperature_k,
        composition,
    )
    dP_dρ = Microphysics.pressure_density_derivative(
        problem.microphysics.eos,
        density_g_cm3,
        temperature_k,
        composition,
    )
    prefactor =
        3.0 * luminosity_erg_s /
        (
            16.0 *
            π *
            RADIATION_CONSTANT_CGS *
            SPEED_OF_LIGHT_CGS *
            GRAVITATIONAL_CONSTANT_CGS *
            clip_positive(enclosed_mass_g) *
            temperature_k^4
        )
    density_term =
        dκ_dρ * eos_state.pressure_dyn_cm2 +
        opacity_state.opacity_cm2_g * dP_dρ
    return prefactor * density_term
end
