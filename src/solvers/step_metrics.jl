const _ASTRA_MODULE = Base.parentmodule(@__MODULE__)
const ARMIJO_SUFFICIENT_DECREASE = 1.0e-2

_safe_scale(value::Real) = max(abs(Float64(value)), eps(Float64))

_scale_weight(value::Real) = 1.0 / _safe_scale(value)

function _luminosity_reference_scale(
    problem::StructureProblem,
    model::StellarModel,
    k::Int,
)
    luminosity_face_erg_s = model.structure.luminosity_face_erg_s
    center_floor_erg_s = center_luminosity_series_target_erg_s(problem, model)
    surface_target_erg_s = problem.parameters.luminosity_guess_erg_s
    return max(
        abs(luminosity_face_erg_s[k]),
        abs(surface_target_erg_s),
        abs(center_floor_erg_s),
    )
end

function _surface_match_pressure_reference_scale(problem::StructureProblem, model::StellarModel)
    n = problem.grid.n_cells
    radius_surface_cm = exp(model.structure.log_radius_face_cm[end])
    pressure_surface_dyn_cm2 = cell_eos_state(problem, model, n).pressure_dyn_cm2
    pressure_match_dyn_cm2 = _ASTRA_MODULE.outer_match_pressure_dyn_cm2(problem, model)
    return max(
        abs(pressure_surface_dyn_cm2),
        abs(pressure_match_dyn_cm2),
    )
end

function _interior_transport_reference_scale(
    problem::StructureProblem,
    model::StellarModel,
    k::Int,
)
    state = model.structure
    pressure_k_dyn_cm2 = cell_eos_state(problem, model, k).pressure_dyn_cm2
    pressure_kp1_dyn_cm2 = cell_eos_state(problem, model, k + 1).pressure_dyn_cm2
    delta_log_temperature = state.log_temperature_cell_k[k + 1] - state.log_temperature_cell_k[k]
    delta_log_pressure =
        log(_safe_scale(pressure_kp1_dyn_cm2)) - log(_safe_scale(pressure_k_dyn_cm2))
    gradient_term =
        _ASTRA_MODULE.radiative_temperature_gradient(problem, model, k) * delta_log_pressure
    return max(abs(delta_log_temperature), abs(gradient_term), 1.0)
end

function _outer_transport_reference_scale(
    problem::StructureProblem,
    model::StellarModel,
    k::Int,
)
    state = model.structure
    n = problem.grid.n_cells
    radius_surface_cm = exp(state.log_radius_face_cm[end])
    luminosity_surface_erg_s = state.luminosity_face_erg_s[end]
    face_temperature_k = _ASTRA_MODULE.surface_effective_temperature_k(
        radius_surface_cm,
        luminosity_surface_erg_s,
    )
    outer_cell_pressure_dyn_cm2 = cell_eos_state(problem, model, k).pressure_dyn_cm2
    surface_gravity_cgs_value =
        _ASTRA_MODULE.surface_gravity_cgs(problem.parameters.mass_g, radius_surface_cm)
    opacity_outer_cm2_g = _ASTRA_MODULE.cell_opacity_state(problem, model, n).opacity_cm2_g
    face_pressure_dyn_cm2 = _ASTRA_MODULE.eddington_photospheric_pressure_dyn_cm2(
        surface_gravity_cgs_value,
        opacity_outer_cm2_g,
    )
    delta_log_temperature =
        _ASTRA_MODULE.positive_log(face_temperature_k) - state.log_temperature_cell_k[k]
    delta_log_pressure =
        log(_safe_scale(face_pressure_dyn_cm2)) - log(_safe_scale(outer_cell_pressure_dyn_cm2))
    gradient_term =
        _ASTRA_MODULE.radiative_temperature_gradient(problem, model, k) * delta_log_pressure
    return max(abs(delta_log_temperature), abs(gradient_term), 1.0)
end

"""
    residual_row_weights(problem, model)

Return solver-side row weights for the current residual vector. These weights
make Newton acceptance and convergence metrics dimensionless without changing
the physical residual definition.
"""
function residual_row_weights(problem::StructureProblem, model::StellarModel)
    n = problem.grid.n_cells
    weights = Vector{Float64}(undef, 4 * n + 2)

    center_rows = structure_center_row_range()
    weights[first(center_rows)] = _scale_weight(center_radius_series_target_cm(problem, model))
    weights[last(center_rows)] = _scale_weight(center_luminosity_series_target_erg_s(problem, model))

    state = model.structure
    for k in 1:(n - 1)
        row_range = interior_structure_row_range(k)
        r_left_cm = exp(state.log_radius_face_cm[k])
        r_right_cm = exp(state.log_radius_face_cm[k + 1])
        density_g_cm3 = exp(state.log_density_cell_g_cm3[k])
        pressure_k_dyn_cm2 = cell_eos_state(problem, model, k).pressure_dyn_cm2
        pressure_kp1_dyn_cm2 = cell_eos_state(problem, model, k + 1).pressure_dyn_cm2
        energy_rate_erg_g_s = cell_energy_source_state(problem, model, k).eps_total_erg_g_s
        dm_g = problem.grid.dm_cell_g[k]
        enclosed_mass_g = problem.grid.m_face_g[k + 1]
        geometry_scale = max(
            shell_volume_cm3(r_left_cm, r_right_cm),
            dm_g / _safe_scale(density_g_cm3),
        )
        gravity_term_dyn_cm2 =
            GRAVITATIONAL_CONSTANT_CGS * enclosed_mass_g * dm_g / (4.0 * π * _safe_scale(r_right_cm)^4)
        hydrostatic_scale = max(
            max(abs(pressure_k_dyn_cm2), abs(pressure_kp1_dyn_cm2)),
            abs(gravity_term_dyn_cm2),
        )
        luminosity_scale = max(
            max(abs(state.luminosity_face_erg_s[k]), abs(state.luminosity_face_erg_s[k + 1])),
            abs(dm_g * energy_rate_erg_g_s),
        )

        weights[first(row_range)] = _scale_weight(geometry_scale)
        weights[first(row_range) + 1] = _scale_weight(hydrostatic_scale)
        weights[first(row_range) + 2] = _scale_weight(luminosity_scale)
        transport_scale =
            k == n - 1 ?
            _outer_transport_reference_scale(problem, model, k) :
            _interior_transport_reference_scale(problem, model, k)
        weights[first(row_range) + 3] = _scale_weight(transport_scale)
    end

    surface_rows = structure_surface_row_range(n)
    weights[surface_rows[1]] = _scale_weight(problem.parameters.radius_guess_cm)
    weights[surface_rows[2]] = _scale_weight(problem.parameters.luminosity_guess_erg_s)
    weights[surface_rows[3]] = 1.0
    weights[surface_rows[4]] = _scale_weight(_surface_match_pressure_reference_scale(problem, model))
    return weights
end

weighted_residual(
    problem::StructureProblem,
    model::StellarModel,
    residual::AbstractVector{<:Real},
) = residual_row_weights(problem, model) .* Float64.(residual)

function weighted_residual_merit(
    residual::AbstractVector{<:Real},
    row_weights::AbstractVector{<:Real},
)
    weighted = Float64.(residual) .* Float64.(row_weights)
    return 0.5 * sum(abs2, weighted)
end

function weighted_residual_merit(
    problem::StructureProblem,
    model::StellarModel,
    residual::AbstractVector{<:Real},
)
    return weighted_residual_merit(residual, residual_row_weights(problem, model))
end

function weighted_merit_slope(
    residual::AbstractVector{<:Real},
    jacobian_times_step::AbstractVector{<:Real},
    row_weights::AbstractVector{<:Real},
)
    weighted_residual = Float64.(row_weights) .* Float64.(residual)
    weighted_jstep = Float64.(row_weights) .* Float64.(jacobian_times_step)
    return dot(weighted_residual, weighted_jstep)
end

function linearized_weighted_residual_merit(
    residual::AbstractVector{<:Real},
    jacobian_times_step::AbstractVector{<:Real},
    row_weights::AbstractVector{<:Real};
    damping::Real = 1.0,
)
    weighted_residual = Float64.(row_weights) .* Float64.(residual)
    weighted_jstep = Float64.(row_weights) .* Float64.(jacobian_times_step)
    return 0.5 * sum(abs2, weighted_residual .+ Float64(damping) .* weighted_jstep)
end

function predicted_merit_decrease(
    residual::AbstractVector{<:Real},
    jacobian_times_step::AbstractVector{<:Real},
    row_weights::AbstractVector{<:Real};
    damping::Real = 1.0,
)
    base_merit = weighted_residual_merit(residual, row_weights)
    predicted_merit = linearized_weighted_residual_merit(
        residual,
        jacobian_times_step,
        row_weights;
        damping = damping,
    )
    return base_merit - predicted_merit
end

actual_merit_decrease(base_merit::Real, trial_merit::Real) = Float64(base_merit) - Float64(trial_merit)

function merit_decrease_ratio(predicted_decrease::Real, actual_decrease::Real)
    Float64(predicted_decrease) > 0.0 || return NaN
    return Float64(actual_decrease) / Float64(predicted_decrease)
end

armijo_target_merit(base_merit::Real, damping::Real, slope::Real) =
    Float64(base_merit) + ARMIJO_SUFFICIENT_DECREASE * Float64(damping) * Float64(slope)

function weighted_residual_norm(
    residual::AbstractVector{<:Real},
    row_weights::AbstractVector{<:Real},
)
    weighted = Float64.(residual) .* Float64.(row_weights)
    return norm(weighted) / sqrt(length(weighted))
end

function weighted_residual_norm(
    problem::StructureProblem,
    model::StellarModel,
    residual::AbstractVector{<:Real},
)
    return weighted_residual_norm(residual, residual_row_weights(problem, model))
end

function _family_merit(weighted_residual::AbstractVector{<:Real}, row_range)
    return 0.5 * sum(abs2, view(weighted_residual, row_range))
end

function row_family_merit_summary(
    problem::StructureProblem,
    model::StellarModel,
    residual::AbstractVector{<:Real};
    row_weights::AbstractVector{<:Real} = residual_row_weights(problem, model),
)
    weighted_residual = Float64.(residual) .* Float64.(row_weights)
    n = problem.grid.n_cells

    center = _family_merit(weighted_residual, structure_center_row_range())
    geometry = 0.0
    hydrostatic = 0.0
    luminosity = 0.0
    interior_transport = 0.0
    outer_transport = 0.0
    transport = 0.0

    for k in 1:(n - 1)
        row_range = interior_structure_row_range(k)
        row = first(row_range)
        geometry += _family_merit(weighted_residual, row:row)
        hydrostatic += _family_merit(weighted_residual, (row + 1):(row + 1))
        luminosity += _family_merit(weighted_residual, (row + 2):(row + 2))
        if k == n - 1
            outer_transport += _family_merit(weighted_residual, (row + 3):(row + 3))
        else
            interior_transport += _family_merit(weighted_residual, (row + 3):(row + 3))
        end
    end

    transport = interior_transport + outer_transport
    surface = _family_merit(weighted_residual, structure_surface_row_range(n))
    total = center + geometry + hydrostatic + luminosity + transport + surface
    family_values = (
        center,
        geometry,
        hydrostatic,
        luminosity,
        interior_transport,
        outer_transport,
        surface,
    )
    family_names = (
        :center,
        :geometry,
        :hydrostatic,
        :luminosity,
        :interior_transport,
        :outer_transport,
        :surface,
    )
    dominant_family = family_names[argmax(family_values)]

    return _ASTRA_MODULE.RowFamilyMeritSummary(
        center,
        geometry,
        hydrostatic,
        luminosity,
        interior_transport,
        outer_transport,
        transport,
        surface,
        total,
        dominant_family,
    )
end

"""
    correction_weights(problem, model)

Return solver-side weights for packed Newton corrections. Log-state variables
are already dimensionless; luminosity stays linear in cgs `erg/s` and therefore
gets an explicit inverse scale.
"""
function correction_weights(problem::StructureProblem, model::StellarModel)
    n = problem.grid.n_cells
    weights = ones(Float64, length(pack_state(model.structure)))
    for k in 1:(n + 1)
        weights[n + 1 + k] = _scale_weight(
            _luminosity_reference_scale(problem, model, k),
        )
    end
    return weights
end

weighted_correction(
    problem::StructureProblem,
    model::StellarModel,
    update::AbstractVector{<:Real},
) = correction_weights(problem, model) .* Float64.(update)

function weighted_correction_norm(
    problem::StructureProblem,
    model::StellarModel,
    update::AbstractVector{<:Real},
)
    weighted = weighted_correction(problem, model, update)
    return norm(weighted) / sqrt(length(weighted))
end

function weighted_max_correction(
    problem::StructureProblem,
    model::StellarModel,
    update::AbstractVector{<:Real},
)
    weighted = weighted_correction(problem, model, update)
    return maximum(abs, weighted)
end

"""
    limit_weighted_correction(problem, model, update)

Uniformly shrink a packed Newton correction so both the weighted RMS correction
and the weighted max correction are at most unity.
"""
function limit_weighted_correction(
    problem::StructureProblem,
    model::StellarModel,
    update::AbstractVector{<:Real},
)
    update_f64 = Float64.(update)
    correction_norm = weighted_correction_norm(problem, model, update_f64)
    max_correction = weighted_max_correction(problem, model, update_f64)
    factor = min(
        1.0,
        1.0 / max(correction_norm, 1.0),
        1.0 / max(max_correction, 1.0),
    )
    limited_update = factor .* update_f64
    return (
        factor = factor,
        update = limited_update,
        weighted_correction_norm = weighted_correction_norm(problem, model, limited_update),
        weighted_max_correction = weighted_max_correction(problem, model, limited_update),
    )
end
