"""
    Composition(X, Y, Z)

Mass-fraction composition in cgs-style scalar form. The constructor enforces a
closed composition simplex for bootstrap work.
"""
struct Composition
    X::Float64
    Y::Float64
    Z::Float64

    function Composition(X::Real, Y::Real, Z::Real)
        values = Float64.((X, Y, Z))
        all(>=(0.0), values) || throw(ArgumentError("Composition fractions must be non-negative."))
        isapprox(sum(values), 1.0; atol = 1.0e-12) || throw(
            ArgumentError("Composition fractions must sum to one."),
        )
        return new(values...)
    end
end

"""
    StellarParameters(; kwargs...)

Scalar parameters controlling ASTRA's bootstrap stellar model family.
"""
struct StellarParameters
    mass_g::Float64
    radius_guess_cm::Float64
    luminosity_guess_erg_s::Float64
    center_temperature_guess_k::Float64
    surface_temperature_guess_k::Float64
    center_density_guess_g_cm3::Float64

    function StellarParameters(;
        mass_g::Real,
        radius_guess_cm::Real = SOLAR_RADIUS_CM,
        luminosity_guess_erg_s::Real = SOLAR_LUMINOSITY_ERG_S,
        center_temperature_guess_k::Real = 1.5e7,
        surface_temperature_guess_k::Real = SOLAR_EFFECTIVE_TEMPERATURE_K,
        center_density_guess_g_cm3::Real = 150.0,
    )
        mass_g > 0.0 || throw(ArgumentError("mass_g must be positive."))
        radius_guess_cm > 0.0 || throw(ArgumentError("radius_guess_cm must be positive."))
        luminosity_guess_erg_s > 0.0 || throw(
            ArgumentError("luminosity_guess_erg_s must be positive."),
        )
        center_temperature_guess_k > surface_temperature_guess_k > 0.0 || throw(
            ArgumentError("Temperature guesses must be positive and center > surface."),
        )
        center_density_guess_g_cm3 > 0.0 || throw(
            ArgumentError("center_density_guess_g_cm3 must be positive."),
        )
        return new(
            Float64(mass_g),
            Float64(radius_guess_cm),
            Float64(luminosity_guess_erg_s),
            Float64(center_temperature_guess_k),
            Float64(surface_temperature_guess_k),
            Float64(center_density_guess_g_cm3),
        )
    end
end

"""
    StellarGrid(m_face_g, dm_cell_g, n_cells)

Mass-coordinate grid used by the bootstrap state and residual scaffolds.
"""
struct StellarGrid
    m_face_g::Vector{Float64}
    dm_cell_g::Vector{Float64}
    n_cells::Int

    function StellarGrid(m_face_g::Vector{Float64}, dm_cell_g::Vector{Float64}, n_cells::Int)
        length(m_face_g) == n_cells + 1 || throw(
            ArgumentError("m_face_g must contain n_cells + 1 entries."),
        )
        length(dm_cell_g) == n_cells || throw(
            ArgumentError("dm_cell_g must contain n_cells entries."),
        )
        all(diff(m_face_g) .> 0.0) || throw(ArgumentError("m_face_g must be strictly increasing."))
        all(dm_cell_g .> 0.0) || throw(ArgumentError("dm_cell_g must be positive."))
        return new(m_face_g, dm_cell_g, n_cells)
    end
end

"""
    StructureState(grid, log_radius_face_cm, luminosity_face_erg_s,
                   log_temperature_cell_k, log_density_cell_g_cm3)

Persistent structure block for ASTRA's bootstrap stellar model. This is the
canonical solve-owned state block for the classical lane.
"""
struct StructureState
    grid::StellarGrid
    log_radius_face_cm::Vector{Float64}
    luminosity_face_erg_s::Vector{Float64}
    log_temperature_cell_k::Vector{Float64}
    log_density_cell_g_cm3::Vector{Float64}

    function StructureState(
        grid::StellarGrid,
        log_radius_face_cm::Vector{Float64},
        luminosity_face_erg_s::Vector{Float64},
        log_temperature_cell_k::Vector{Float64},
        log_density_cell_g_cm3::Vector{Float64},
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
        return new(
            grid,
            log_radius_face_cm,
            luminosity_face_erg_s,
            log_temperature_cell_k,
            log_density_cell_g_cm3,
        )
    end
end

"""
    CompositionState(hydrogen_mass_fraction_cell, helium_mass_fraction_cell,
                     metal_mass_fraction_cell)

Persistent cell-centered bulk composition block for ASTRA's bootstrap stellar
model.
"""
struct CompositionState
    hydrogen_mass_fraction_cell::Vector{Float64}
    helium_mass_fraction_cell::Vector{Float64}
    metal_mass_fraction_cell::Vector{Float64}

    function CompositionState(
        hydrogen_mass_fraction_cell::Vector{Float64},
        helium_mass_fraction_cell::Vector{Float64},
        metal_mass_fraction_cell::Vector{Float64},
    )
        n = length(hydrogen_mass_fraction_cell)
        length(helium_mass_fraction_cell) == n || throw(
            ArgumentError("helium_mass_fraction_cell must match hydrogen length."),
        )
        length(metal_mass_fraction_cell) == n || throw(
            ArgumentError("metal_mass_fraction_cell must match hydrogen length."),
        )
        return new(
            hydrogen_mass_fraction_cell,
            helium_mass_fraction_cell,
            metal_mass_fraction_cell,
        )
    end
end

"""
    EvolutionState(age_s, timestep_s, previous_timestep_s, accepted_steps, rejected_steps)

Persistent evolution-metadata block for ASTRA's bootstrap stellar model.
The optional previous thermodynamic profiles are used by the internal
analytical energy-source lane to recover gravothermal terms without widening
the public solve-owned state contract.
"""
struct EvolutionState
    age_s::Float64
    timestep_s::Float64
    previous_timestep_s::Float64
    accepted_steps::Int
    rejected_steps::Int
    previous_log_temperature_cell_k::Union{Nothing,Vector{Float64}}
    previous_log_density_cell_g_cm3::Union{Nothing,Vector{Float64}}

    function EvolutionState(
        age_s::Real,
        timestep_s::Real,
        previous_timestep_s::Real,
        accepted_steps::Int,
        rejected_steps::Int,
    )
        return new(
            Float64(age_s),
            Float64(timestep_s),
            Float64(previous_timestep_s),
            accepted_steps,
            rejected_steps,
            nothing,
            nothing,
        )
    end

    function EvolutionState(
        age_s::Real,
        timestep_s::Real,
        previous_timestep_s::Real,
        accepted_steps::Int,
        rejected_steps::Int,
        previous_log_temperature_cell_k::Union{Nothing,Vector{Float64}},
        previous_log_density_cell_g_cm3::Union{Nothing,Vector{Float64}},
    )
        if xor(
            previous_log_temperature_cell_k === nothing,
            previous_log_density_cell_g_cm3 === nothing,
        )
            throw(ArgumentError("Previous thermodynamic profiles must be provided together."))
        end
        if previous_log_temperature_cell_k !== nothing &&
           previous_log_density_cell_g_cm3 !== nothing &&
           length(previous_log_temperature_cell_k) != length(previous_log_density_cell_g_cm3)
            throw(ArgumentError("Previous thermodynamic profiles must have matching lengths."))
        end
        return new(
            Float64(age_s),
            Float64(timestep_s),
            Float64(previous_timestep_s),
            accepted_steps,
            rejected_steps,
            previous_log_temperature_cell_k,
            previous_log_density_cell_g_cm3,
        )
    end
end

"""
    StellarModel(structure, composition, evolution)

Top-level persistent model container bundling ASTRA's explicit state-ownership
blocks.
"""
struct StellarModel{S,C,E}
    structure::S
    composition::C
    evolution::E
end

"""
    MicrophysicsBundle(eos, opacity, nuclear, convection)

Type-stable container for ASTRA's microphysics callables.
"""
struct MicrophysicsBundle{E,O,N,C}
    eos::E
    opacity::O
    nuclear::N
    convection::C
end

"""
    StructureProblem(formulation, parameters, composition, grid, microphysics, solver)

Immutable problem bundle for ASTRA's structure solve.
"""
struct StructureProblem{F,M}
    formulation::F
    parameters::StellarParameters
    composition::Composition
    grid::StellarGrid
    microphysics::M
    solver::SolverConfig
end

"""
    StructureDiagnostics(...)

Summary diagnostics returned by ASTRA's bootstrap solve.
"""
struct StructureDiagnostics
    residual_norm::Float64
    initial_residual_norm::Float64
    residual_history::Vector{Float64}
    damping_history::Vector{Float64}
    accepted_step_count::Int
    rejected_trial_count::Int
    converged::Bool
    iterations::Int
    center_pressure_dyn_cm2::Float64
    surface_luminosity_erg_s::Float64
    formulation::Symbol
    notes::Vector{String}
end

"""
    SolveResult(state, diagnostics)

Container returned by `solve_structure`.
"""
struct SolveResult{S,D}
    state::S
    diagnostics::D
end
