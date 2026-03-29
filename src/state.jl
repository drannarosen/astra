"""
    StellarState

Internal transitional bootstrap state for ASTRA's legacy structure solver path.
"""
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

toy_reference_state(problem::StructureProblem) =
    _analytic_profile_state(problem.parameters, problem.composition, problem.grid)

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

initialize_state(problem::StructureProblem) =
    initialize_state(problem.parameters, problem.composition, problem.grid)

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
