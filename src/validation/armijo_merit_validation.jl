"""
    build_armijo_merit_validation_payload(fixture_label, problem, result; seed_label)

Build a validation-only payload from a completed Armijo-controlled structure solve.
The payload copies the recorded histories and surfaces the controller evidence
needed for downstream scientific interpretation.
"""
function build_armijo_merit_validation_payload(
    fixture_label::AbstractString,
    problem::StructureProblem,
    result::SolveResult;
    seed_label::AbstractString,
)
    diagnostics = result.diagnostics
    accepted_dominant_family = isempty(diagnostics.accepted_trial_history) ?
        nothing :
        diagnostics.accepted_trial_history[end].row_family_merit.dominant_family
    used_regularized_fallback = any(
        note -> begin
            lowered = lowercase(note)
            occursin("regularized normal equations", lowered) ||
                occursin("retrying with regularization", lowered)
        end,
        diagnostics.notes,
    )

    return ArmijoMeritValidationPayload(
        String(fixture_label),
        String(seed_label),
        problem.grid.n_cells,
        diagnostics.converged,
        diagnostics.accepted_step_count,
        diagnostics.rejected_trial_count,
        diagnostics.residual_norm,
        diagnostics.weighted_residual_norm,
        diagnostics.merit_value,
        copy(diagnostics.predicted_decrease_history),
        copy(diagnostics.actual_decrease_history),
        copy(diagnostics.decrease_ratio_history),
        accepted_dominant_family,
        diagnostics.best_rejected_trial,
        used_regularized_fallback,
    )
end
