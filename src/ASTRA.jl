module ASTRA

using LinearAlgebra

export StellarParameters,
    Composition,
    GridConfig,
    SolverConfig,
    StellarGrid,
    StructureState,
    CompositionState,
    EvolutionState,
    StellarModel,
    MicrophysicsBundle,
    StructureProblem,
    SolveResult,
    StructureDiagnostics,
    AbstractFormulation,
    ClassicalHenyeyFormulation,
    EntropyDAEFormulation,
    initialize_state,
    build_grid,
    solve_structure,
    step_evolution!,
    shell_volume_cm3,
    cell_composition,
    cell_eos_state,
    cell_opacity_state,
    cell_nuclear_state,
    radiative_temperature_gradient,
    surface_effective_temperature_k,
    surface_gravity_cgs,
    eddington_photospheric_pressure_dyn_cm2,
    eddington_t_tau_temperature_k,
    outer_half_cell_column_density_g_cm2,
    outer_half_cell_optical_depth,
    outer_match_optical_depth,
    outer_match_temperature_k,
    outer_match_pressure_dyn_cm2

include("foundation/constants.jl")
include("foundation/units.jl")
include("foundation/config.jl")
include("foundation/types.jl")
include("foundation/grid.jl")
include("foundation/state.jl")
include("numerics/atmosphere.jl")

module Microphysics
using ..ASTRA: BOLTZMANN_CONSTANT_CGS,
    HYDROGEN_MASS_CGS,
    RADIATION_CONSTANT_CGS,
    clip_positive,
    Composition,
    EvolutionState,
    StellarModel,
    StructureProblem

include("microphysics/eos.jl")
include("microphysics/energy_sources.jl")
include("microphysics/opacity.jl")
include("microphysics/nuclear.jl")
include("microphysics/convection.jl")
end

using .Microphysics: energy_source_terms

include("numerics/boundary_conditions.jl")
include("numerics/structure_equations.jl")
include("numerics/residuals.jl")
include("numerics/jacobians.jl")

module Formulations
include("formulations/abstract_formulation.jl")
include("formulations/classical_henyey.jl")
include("formulations/entropy_dae.jl")
end

using .Formulations: AbstractFormulation, ClassicalHenyeyFormulation, EntropyDAEFormulation

include("numerics/diagnostics.jl")
include("io.jl")

module Solvers
using LinearAlgebra
using ..ASTRA: SOLAR_LUMINOSITY_ERG_S,
    GRAVITATIONAL_CONSTANT_CGS,
    SolveResult,
    StructureProblem,
    StructureDiagnostics,
    StellarModel,
    assemble_structure_residual,
    build_diagnostics,
    cell_energy_source_state,
    cell_eos_state,
    center_luminosity_series_target_erg_s,
    center_radius_series_target_cm,
    finite_difference_jacobian,
    interior_structure_row_range,
    structure_jacobian,
    structure_center_row_range,
    structure_surface_row_range,
    shell_volume_cm3,
    pack_state,
    residual_norm,
    unpack_state,
    SURFACE_DENSITY_GUESS_G_CM3

include("solvers/linear_solvers.jl")
include("solvers/step_metrics.jl")
include("solvers/convergence.jl")
include("solvers/nonlinear_solvers.jl")
end

module Evolution
using ..ASTRA: StellarModel, StructureProblem

include("evolution/timestepping.jl")
include("evolution/controllers.jl")
include("evolution/update.jl")
end

using .Evolution: step_evolution!

"""
    default_microphysics()

Return the toy microphysics bundle used by the bootstrap examples and tests.
This bundle is intentionally simple and exists to exercise ASTRA's architecture,
not to claim production microphysics fidelity.
"""
function default_microphysics()
    return MicrophysicsBundle(
        Microphysics.AnalyticalGasRadiationEOS(),
        Microphysics.AnalyticalOpacity(),
        Microphysics.AnalyticalNuclear(),
        Microphysics.SchwarzschildConvectionHook(),
    )
end

"""
    build_toy_problem(; n_cells = 16, formulation = ClassicalHenyeyFormulation())

Construct a small bootstrap problem used by the tests, scripts, and examples.
"""
function build_toy_problem(;
    n_cells::Int = 16,
    formulation::AbstractFormulation = ClassicalHenyeyFormulation(),
)
    parameters = StellarParameters(mass_g = SOLAR_MASS_G)
    composition = Composition(0.70, 0.28, 0.02)
    grid = build_grid(parameters, GridConfig(n_cells = n_cells))
    microphysics = default_microphysics()
    solver = SolverConfig()
    return StructureProblem(formulation, parameters, composition, grid, microphysics, solver)
end

"""
    solve_structure(problem; state = nothing)

Run ASTRA's bootstrap nonlinear solve for a structure problem.

At bootstrap stage, the classical lane solves a toy reference-profile residual
system that exercises the package architecture, state packing, Jacobian
construction, and convergence bookkeeping. This public entry point is also
ASTRA's current solve boundary for future sensitivity work: only
`model.structure` is solve-owned, while composition and evolution remain
attached to the returned `StellarModel`. It is not yet a research-grade stellar
structure solve.
"""
function solve_structure(
    problem::StructureProblem;
    state::Union{Nothing,StellarModel} = nothing,
)
    working_model = isnothing(state) ? initialize_state(problem) : state

    if problem.formulation isa ClassicalHenyeyFormulation
        return Solvers.solve_nonlinear_system(problem, working_model)
    elseif problem.formulation isa EntropyDAEFormulation
        throw(ArgumentError("Entropy-DAE is intentionally stubbed during ASTRA bootstrap."))
    else
        throw(ArgumentError("Unsupported formulation $(typeof(problem.formulation))."))
    end
end

end
