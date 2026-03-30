"""
    StellarState

Internal transitional bootstrap state for ASTRA's legacy structure solver path.
"""
const INITIAL_SURFACE_DENSITY_G_CM3 = 1.0e-7

struct StellarState
    grid::StellarGrid
    log_radius_face_cm::Vector{Float64}
    luminosity_face_erg_s::Vector{Float64}
    log_temperature_cell_k::Vector{Float64}
    log_density_cell_g_cm3::Vector{Float64}
    hydrogen_mass_fraction_cell::Vector{Float64}
    helium_mass_fraction_cell::Vector{Float64}
    metal_mass_fraction_cell::Vector{Float64}

    function StellarState(
        grid::StellarGrid,
        log_radius_face_cm::Vector{Float64},
        luminosity_face_erg_s::Vector{Float64},
        log_temperature_cell_k::Vector{Float64},
        log_density_cell_g_cm3::Vector{Float64},
        hydrogen_mass_fraction_cell::Vector{Float64},
        helium_mass_fraction_cell::Vector{Float64},
        metal_mass_fraction_cell::Vector{Float64},
    )
        n = grid.n_cells
        length(log_radius_face_cm) == n + 1 || throw(
            ArgumentError("log_radius_face_cm must have n_cells + 1 entries."),
        )
        length(luminosity_face_erg_s) == n + 1 || throw(
            ArgumentError("luminosity_face_erg_s must have n_cells + 1 entries."),
        )
        length(log_temperature_cell_k) == n || throw(
            ArgumentError("log_temperature_cell_k must have n_cells entries."),
        )
        length(log_density_cell_g_cm3) == n || throw(
            ArgumentError("log_density_cell_g_cm3 must have n_cells entries."),
        )
        length(hydrogen_mass_fraction_cell) == n || throw(
            ArgumentError("hydrogen_mass_fraction_cell must have n_cells entries."),
        )
        length(helium_mass_fraction_cell) == n || throw(
            ArgumentError("helium_mass_fraction_cell must have n_cells entries."),
        )
        length(metal_mass_fraction_cell) == n || throw(
            ArgumentError("metal_mass_fraction_cell must have n_cells entries."),
        )
        return new(
            grid,
            log_radius_face_cm,
            luminosity_face_erg_s,
            log_temperature_cell_k,
            log_density_cell_g_cm3,
            hydrogen_mass_fraction_cell,
            helium_mass_fraction_cell,
            metal_mass_fraction_cell,
        )
    end
end

function _normalized_cell_mass_fraction(grid::StellarGrid)
    m_inner_g = grid.m_face_g[1]
    total_span_g = grid.m_face_g[end] - m_inner_g
    cell_center_mass_g = 0.5 .* (grid.m_face_g[1:end-1] .+ grid.m_face_g[2:end])
    return (cell_center_mass_g .- m_inner_g) ./ clip_positive(total_span_g)
end

_density_shape(mass_fraction::Real) = 1.0 - Float64(mass_fraction)^2

function _density_profile_for_log_amplitude(
    grid::StellarGrid,
    log_amplitude::Real;
    surface_density_g_cm3::Real = INITIAL_SURFACE_DENSITY_G_CM3,
)
    cell_fraction = _normalized_cell_mass_fraction(grid)
    return surface_density_g_cm3 .* exp.(Float64(log_amplitude) .* _density_shape.(cell_fraction))
end

function _radius_faces_from_density(
    grid::StellarGrid,
    density_cell_g_cm3::AbstractVector{<:Real},
)
    radius_face_cm = Vector{Float64}(undef, grid.n_cells + 1)
    radius_face_cm[1] = (
        3.0 * grid.m_face_g[1] / (4.0 * π * clip_positive(density_cell_g_cm3[1]))
    )^(1.0 / 3.0)

    for k in 1:grid.n_cells
        shell_volume_cm3 = grid.dm_cell_g[k] / clip_positive(density_cell_g_cm3[k])
        radius_face_cm[k + 1] = (
            clip_positive(radius_face_cm[k])^3 + 3.0 * shell_volume_cm3 / (4.0 * π)
        )^(1.0 / 3.0)
    end

    return radius_face_cm
end

function _target_radius_faces(parameters::StellarParameters, grid::StellarGrid)
    mass_fraction_face = grid.m_face_g ./ parameters.mass_g
    return parameters.radius_guess_cm .* mass_fraction_face .^ (1.0 / 3.0)
end

function _geometry_consistent_density_profile(
    grid::StellarGrid,
    radius_face_cm::AbstractVector{<:Real},
)
    density_cell_g_cm3 = Vector{Float64}(undef, grid.n_cells)
    for k in 1:grid.n_cells
        density_cell_g_cm3[k] =
            grid.dm_cell_g[k] / shell_volume_cm3(radius_face_cm[k], radius_face_cm[k + 1])
    end
    return density_cell_g_cm3
end

function _radius_calibrated_density_profile(parameters::StellarParameters, grid::StellarGrid)
    target_radius_cm = parameters.radius_guess_cm
    log_amplitude_low = 0.0
    log_amplitude_high = max(
        1.0,
        log(parameters.center_density_guess_g_cm3 / INITIAL_SURFACE_DENSITY_G_CM3),
    )

    outer_radius(log_amplitude) =
        _radius_faces_from_density(
            grid,
            _density_profile_for_log_amplitude(grid, log_amplitude),
        )[end]

    while outer_radius(log_amplitude_high) > target_radius_cm && log_amplitude_high < 96.0
        log_amplitude_high *= 1.5
    end

    for _ in 1:40
        midpoint = 0.5 * (log_amplitude_low + log_amplitude_high)
        if outer_radius(midpoint) > target_radius_cm
            log_amplitude_low = midpoint
        else
            log_amplitude_high = midpoint
        end
    end

    return _density_profile_for_log_amplitude(grid, log_amplitude_high)
end

_mean_molecular_weight(composition::Composition) =
    1.0 / (2.0 * composition.X + 0.75 * composition.Y + 0.5 * composition.Z)

function _hydrostatic_temperature_profile(
    problem::StructureProblem,
    radius_face_cm::AbstractVector{<:Real},
    density_cell_g_cm3::AbstractVector{<:Real},
)
    n = problem.grid.n_cells
    surface_temperature_k = problem.parameters.surface_temperature_guess_k
    composition = problem.composition
    pressure_cell_dyn_cm2 = Vector{Float64}(undef, n)
    pressure_cell_dyn_cm2[end] = problem.microphysics.eos(
        density_cell_g_cm3[end],
        surface_temperature_k,
        composition,
    ).pressure_dyn_cm2

    for k in (n - 1):-1:1
        pressure_cell_dyn_cm2[k] =
            pressure_cell_dyn_cm2[k + 1] +
            GRAVITATIONAL_CONSTANT_CGS * problem.grid.m_face_g[k + 1] * problem.grid.dm_cell_g[k] /
            (4.0 * π * clip_positive(radius_face_cm[k + 1])^4)
    end

    gas_constant_cgs =
        BOLTZMANN_CONSTANT_CGS / (_mean_molecular_weight(composition) * HYDROGEN_MASS_CGS)
    temperature_cell_k = similar(pressure_cell_dyn_cm2)
    for k in 1:n
        temperature_cell_k[k] = max(
            surface_temperature_k,
            pressure_cell_dyn_cm2[k] / (clip_positive(density_cell_g_cm3[k]) * gas_constant_cgs),
        )
    end
    temperature_cell_k[end] = surface_temperature_k
    return temperature_cell_k
end

function _scaled_temperature_profile(
    base_temperature_cell_k::AbstractVector{<:Real},
    surface_temperature_k::Real,
    scale::Real,
)
    temperature_cell_k =
        Float64(surface_temperature_k) .+
        Float64(scale) .* (Float64.(base_temperature_cell_k) .- Float64(surface_temperature_k))
    temperature_cell_k = max.(temperature_cell_k, Float64(surface_temperature_k))
    temperature_cell_k[end] = Float64(surface_temperature_k)
    return temperature_cell_k
end

function _integrated_source_luminosity(
    problem::StructureProblem,
    density_cell_g_cm3::AbstractVector{<:Real},
    temperature_cell_k::AbstractVector{<:Real},
)
    center_energy_rate_erg_g_s = problem.microphysics.nuclear(
        density_cell_g_cm3[1],
        temperature_cell_k[1],
        problem.composition,
    ).energy_rate_erg_g_s
    composition = problem.composition
    return problem.grid.m_face_g[1] * center_energy_rate_erg_g_s + sum(
        problem.grid.dm_cell_g[k] * problem.microphysics.nuclear(
            density_cell_g_cm3[k],
            temperature_cell_k[k],
            composition,
        ).energy_rate_erg_g_s for k in 1:problem.grid.n_cells
    )
end

function _source_matched_temperature_profile(
    problem::StructureProblem,
    density_cell_g_cm3::AbstractVector{<:Real},
    base_temperature_cell_k::AbstractVector{<:Real},
)
    target_luminosity_erg_s = problem.parameters.luminosity_guess_erg_s
    surface_temperature_k = problem.parameters.surface_temperature_guess_k

    integrated_luminosity(scale) = _integrated_source_luminosity(
        problem,
        density_cell_g_cm3,
        _scaled_temperature_profile(base_temperature_cell_k, surface_temperature_k, scale),
    )

    low_scale = 0.0
    high_scale = 1.0
    if integrated_luminosity(low_scale) >= target_luminosity_erg_s
        return _scaled_temperature_profile(base_temperature_cell_k, surface_temperature_k, low_scale)
    end

    high_luminosity = integrated_luminosity(high_scale)
    while high_luminosity < target_luminosity_erg_s && high_scale < 64.0
        high_scale *= 2.0
        high_luminosity = integrated_luminosity(high_scale)
    end

    if high_luminosity < target_luminosity_erg_s
        return _scaled_temperature_profile(base_temperature_cell_k, surface_temperature_k, high_scale)
    end

    for _ in 1:40
        midpoint = 0.5 * (low_scale + high_scale)
        if integrated_luminosity(midpoint) < target_luminosity_erg_s
            low_scale = midpoint
        else
            high_scale = midpoint
        end
    end

    return _scaled_temperature_profile(
        base_temperature_cell_k,
        surface_temperature_k,
        high_scale,
    )
end

function _source_matched_luminosity_profile(
    problem::StructureProblem,
    density_cell_g_cm3::AbstractVector{<:Real},
    temperature_cell_k::AbstractVector{<:Real},
)
    luminosity_face_erg_s = zeros(Float64, problem.grid.n_cells + 1)
    luminosity_face_erg_s[1] = problem.grid.m_face_g[1] * problem.microphysics.nuclear(
        density_cell_g_cm3[1],
        temperature_cell_k[1],
        problem.composition,
    ).energy_rate_erg_g_s
    for k in 1:problem.grid.n_cells
        energy_rate_erg_g_s = problem.microphysics.nuclear(
            density_cell_g_cm3[k],
            temperature_cell_k[k],
            problem.composition,
        ).energy_rate_erg_g_s
        luminosity_face_erg_s[k + 1] =
            luminosity_face_erg_s[k] + problem.grid.dm_cell_g[k] * energy_rate_erg_g_s
    end
    return luminosity_face_erg_s
end

function _problem_aware_initial_state(problem::StructureProblem)
    radius_face_cm = _target_radius_faces(problem.parameters, problem.grid)
    density_cell_g_cm3 = _geometry_consistent_density_profile(problem.grid, radius_face_cm)
    hydrostatic_temperature_cell_k =
        _hydrostatic_temperature_profile(problem, radius_face_cm, density_cell_g_cm3)
    temperature_cell_k = _source_matched_temperature_profile(
        problem,
        density_cell_g_cm3,
        hydrostatic_temperature_cell_k,
    )
    luminosity_face_erg_s = _source_matched_luminosity_profile(
        problem,
        density_cell_g_cm3,
        temperature_cell_k,
    )

    n = problem.grid.n_cells
    structure = StructureState(
        problem.grid,
        positive_log.(radius_face_cm),
        luminosity_face_erg_s,
        positive_log.(temperature_cell_k),
        positive_log.(density_cell_g_cm3),
    )
    composition_state = CompositionState(
        fill(problem.composition.X, n),
        fill(problem.composition.Y, n),
        fill(problem.composition.Z, n),
    )
    evolution = EvolutionState(0.0, 0.0, 0.0, 0, 0)
    return StellarModel(structure, composition_state, evolution)
end

function _analytic_profile_state(
    parameters::StellarParameters,
    composition::Composition,
    grid::StellarGrid,
)
    mass_fraction_face = grid.m_face_g ./ parameters.mass_g
    radius_face_cm = parameters.radius_guess_cm .* mass_fraction_face .^ (1.0 / 3.0)
    luminosity_face_erg_s = parameters.luminosity_guess_erg_s .* mass_fraction_face

    cell_fraction = @view mass_fraction_face[1:end-1]
    temperature_cell_k =
        parameters.surface_temperature_guess_k .+
        (parameters.center_temperature_guess_k - parameters.surface_temperature_guess_k) .* (
            1.0 .- cell_fraction .^ 0.35
        )
    density_cell_g_cm3 =
        parameters.center_density_guess_g_cm3 .* (1.0 .- 0.92 .* cell_fraction) .+ 1.0e-7

    n = grid.n_cells
    structure = StructureState(
        grid,
        positive_log.(radius_face_cm),
        luminosity_face_erg_s,
        positive_log.(temperature_cell_k),
        positive_log.(density_cell_g_cm3),
    )
    composition_state = CompositionState(
        fill(composition.X, n),
        fill(composition.Y, n),
        fill(composition.Z, n),
    )
    evolution = EvolutionState(0.0, 0.0, 0.0, 0, 0)
    return StellarModel(structure, composition_state, evolution)
end

toy_reference_state(problem::StructureProblem) = _problem_aware_initial_state(problem)

"""
    with_previous_thermodynamic_state(model; kwargs...)

Return a copy of `model` whose evolution metadata carries previous
thermodynamic profiles for the internal analytical gravothermal helper lane.
"""
function with_previous_thermodynamic_state(
    model::StellarModel;
    previous_log_temperature_cell_k::AbstractVector{<:Real},
    previous_log_density_cell_g_cm3::AbstractVector{<:Real},
    timestep_s::Real = model.evolution.timestep_s,
    previous_timestep_s::Real = model.evolution.previous_timestep_s,
    accepted_steps::Int = model.evolution.accepted_steps,
    rejected_steps::Int = model.evolution.rejected_steps,
    age_s::Real = model.evolution.age_s,
)
    n = model.structure.grid.n_cells
    length(previous_log_temperature_cell_k) == n || throw(
        ArgumentError("previous_log_temperature_cell_k must have n_cells entries."),
    )
    length(previous_log_density_cell_g_cm3) == n || throw(
        ArgumentError("previous_log_density_cell_g_cm3 must have n_cells entries."),
    )
    evolution = EvolutionState(
        age_s,
        timestep_s,
        previous_timestep_s,
        accepted_steps,
        rejected_steps,
        Float64.(previous_log_temperature_cell_k),
        Float64.(previous_log_density_cell_g_cm3),
    )
    return StellarModel(model.structure, model.composition, evolution)
end

"""
    initialize_state(parameters, composition, grid)
    initialize_state(problem)

Construct ASTRA's bootstrap reference state from the current problem inputs.
"""
function initialize_state(
    parameters::StellarParameters,
    composition::Composition,
    grid::StellarGrid,
)
    return _analytic_profile_state(parameters, composition, grid)
end

initialize_state(problem::StructureProblem) = _problem_aware_initial_state(problem)

pack_state(state::StructureState) = vcat(
    state.log_radius_face_cm,
    state.luminosity_face_erg_s,
    state.log_temperature_cell_k,
    state.log_density_cell_g_cm3,
)

function unpack_state(template::StructureState, values::AbstractVector{<:Real})
    n = template.grid.n_cells
    expected = 4 * n + 2
    length(values) == expected || throw(
        ArgumentError("Packed state has length $(length(values)); expected $expected."),
    )

    values_f64 = Float64.(values)
    i1 = n + 1
    i2 = 2 * (n + 1)
    i3 = i2 + n
    return StructureState(
        template.grid,
        values_f64[1:i1],
        values_f64[(i1 + 1):i2],
        values_f64[(i2 + 1):i3],
        values_f64[(i3 + 1):end],
    )
end
