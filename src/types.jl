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
