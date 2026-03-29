residual_norm(residual::AbstractVector{<:Real}) = norm(residual)

function formulation_symbol(problem::StructureProblem)
    if problem.formulation isa ClassicalHenyeyFormulation
        return :classical_henyey
    elseif problem.formulation isa EntropyDAEFormulation
        return :entropy_dae_stub
    end
    return Symbol(nameof(typeof(problem.formulation)))
end

function build_diagnostics(
    problem::StructureProblem,
    state::StellarState,
    residual::AbstractVector{<:Real},
    iterations::Integer,
    converged::Bool,
)
    density = exp(state.log_density_cell_g_cm3[1])
    temperature = exp(state.log_temperature_cell_k[1])
    eos_state = problem.microphysics.eos(density, temperature, problem.composition)
    notes = String[
        "Bootstrap solve uses an analytic reference-profile residual system.",
        "Classical baseline is canonical; Entropy-DAE remains a documented stub.",
    ]

    return StructureDiagnostics(
        residual_norm(residual),
        converged,
        Int(iterations),
        eos_state.pressure_dyn_cm2,
        state.luminosity_face_erg_s[end],
        formulation_symbol(problem),
        notes,
    )
end
