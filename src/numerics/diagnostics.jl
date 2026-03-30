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
    model::StellarModel,
    residual::AbstractVector{<:Real},
    initial_residual_norm::Real,
    residual_history::AbstractVector{<:Real},
    weighted_residual_norm_value::Real,
    weighted_residual_history::AbstractVector{<:Real},
    merit_value::Real,
    merit_history::AbstractVector{<:Real},
    predicted_decrease_history::AbstractVector{<:Real},
    actual_decrease_history::AbstractVector{<:Real},
    decrease_ratio_history::AbstractVector{<:Real},
    damping_history::AbstractVector{<:Real},
    weighted_correction_norm_history::AbstractVector{<:Real},
    weighted_max_correction_history::AbstractVector{<:Real},
    accepted_trial_history::AbstractVector{TrialMeritSummary},
    best_rejected_trial::Union{Nothing,TrialMeritSummary},
    accepted_step_count::Integer,
    rejected_trial_count::Integer,
    iterations::Integer,
    converged::Bool,
    initial_row_family_merit::RowFamilyMeritSummary,
    final_row_family_merit::RowFamilyMeritSummary,
    extra_notes::AbstractVector{<:AbstractString} = String[],
)
    state = model.structure
    density = exp(state.log_density_cell_g_cm3[1])
    temperature = exp(state.log_temperature_cell_k[1])
    eos_state = problem.microphysics.eos(density, temperature, cell_composition(problem, model, 1))
    notes = String[
        "Residual now uses the first classical structure equations with simple placeholder closures.",
        "EOS, opacity, convection, and surface closure remain provisional at this milestone.",
        "Classical baseline is canonical; Entropy-DAE remains a documented stub.",
        "Toy model caveat: initialization is architecture-first and numerically helpful, not a physically calibrated stellar seed.",
        "Solve boundary: solve_structure(problem; state = guess) is the current public solve boundary for future sensitivities, with only model.structure treated as solve-owned.",
        "Atmosphere boundary note: surface temperature is matched in log form to T_eff and the surface pressure row is weighted on a pressure scale, not the old density guess.",
        "Solver acceptance now uses the frozen-weight merit controller while convergence still tracks the weighted residual metric; raw residual histories are still reported for scientific honesty.",
        "Weighted residual histories report the frozen acceptance metric used for globalization decisions.",
        "Diagnostics now also report the frozen-weight merit history, initial/final grouped row-family merit summaries, and per-trial predicted/actual merit attribution.",
    ]
    append!(notes, String.(extra_notes))

    return StructureDiagnostics(
        residual_norm(residual),
        Float64(initial_residual_norm),
        Float64.(residual_history),
        Float64(weighted_residual_norm_value),
        Float64.(weighted_residual_history),
        Float64(merit_value),
        Float64.(merit_history),
        Float64.(predicted_decrease_history),
        Float64.(actual_decrease_history),
        Float64.(decrease_ratio_history),
        Float64.(damping_history),
        Float64.(weighted_correction_norm_history),
        Float64.(weighted_max_correction_history),
        collect(accepted_trial_history),
        best_rejected_trial,
        Int(accepted_step_count),
        Int(rejected_trial_count),
        converged,
        Int(iterations),
        eos_state.pressure_dyn_cm2,
        state.luminosity_face_erg_s[end],
        formulation_symbol(problem),
        initial_row_family_merit,
        final_row_family_merit,
        notes,
    )
end
