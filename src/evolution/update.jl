"""
    step_evolution!(state, problem, controller = FixedTimestepController())

Placeholder mutation-oriented evolution entry point for ASTRA's future
time-dependent workflows.
"""
function step_evolution!(
    state::StellarModel,
    problem::StructureProblem,
    controller::AbstractTimestepController = FixedTimestepController(),
)
    throw(
        ArgumentError(
            "Evolution is intentionally stubbed during ASTRA bootstrap. " *
            "Build the classical baseline structure lane before enabling state updates.",
        ),
    )
end
