const _ASTRA_MODULE = Base.parentmodule(@__MODULE__)

function _regularization_ladder(problem::StructureProblem)
    regularization = Float64(problem.solver.linear_regularization)
    ladder = Float64[]
    while true
        push!(ladder, regularization)
        regularization >= 1.0e16 && break
        regularization *= 100.0
    end
    return ladder
end

function _best_rejected_trial(
    best::Union{Nothing,_ASTRA_MODULE.TrialMeritSummary},
    candidate::Union{Nothing,_ASTRA_MODULE.TrialMeritSummary},
)
    candidate === nothing && return best
    best === nothing && return candidate

    candidate_finite = isfinite(candidate.merit_value)
    best_finite = isfinite(best.merit_value)
    if candidate_finite && !best_finite
        return candidate
    elseif candidate_finite == best_finite && candidate.merit_value < best.merit_value
        return candidate
    end
    return best
end

function _accepted_trial_step(
    problem::StructureProblem,
    model::StellarModel,
    residual::AbstractVector{<:Real},
    jacobian,
    update::AbstractVector{<:Real},
)
    base_vector = pack_state(model.structure)
    base_raw_norm = residual_norm(residual)
    base_row_weights = residual_row_weights(problem, model)
    base_weighted_norm = weighted_residual_norm(residual, base_row_weights)
    base_merit = weighted_residual_merit(residual, base_row_weights)
    limited_update = limit_weighted_correction(problem, model, update)
    jacobian_times_step = jacobian * limited_update.update
    base_slope = weighted_merit_slope(residual, jacobian_times_step, base_row_weights)
    damping = problem.solver.damping
    rejected_trials = 0
    best_rejected_trial = nothing
    notes = String[]

    if limited_update.factor < 1.0
        push!(
            notes,
            "Weighted correction limiter scaled the trial step by factor $(limited_update.factor).",
        )
    end

    while damping >= problem.solver.minimum_damping
        damped_update = damping .* limited_update.update
        next_vector = base_vector .+ damped_update
        next_structure = unpack_state(model.structure, next_vector)
        next_model = StellarModel(next_structure, model.composition, model.evolution)
        next_residual = assemble_structure_residual(problem, next_model)
        next_raw_norm = residual_norm(next_residual)
        next_weighted_norm = weighted_residual_norm(next_residual, base_row_weights)
        next_merit = weighted_residual_merit(next_residual, base_row_weights)
        predicted_decrease = predicted_merit_decrease(
            residual,
            jacobian_times_step,
            base_row_weights;
            damping = damping,
        )
        actual_decrease = actual_merit_decrease(base_merit, next_merit)
        decrease_ratio = merit_decrease_ratio(predicted_decrease, actual_decrease)
        armijo_target = armijo_target_merit(base_merit, damping, base_slope)
        trial_summary = _ASTRA_MODULE.TrialMeritSummary(
            damping,
            next_raw_norm,
            next_weighted_norm,
            next_merit,
            armijo_target,
            predicted_decrease,
            actual_decrease,
            decrease_ratio,
            row_family_merit_summary(
                problem,
                next_model,
                next_residual;
                row_weights = base_row_weights,
            ),
        )

        if isfinite(next_merit) &&
           next_merit < base_merit &&
           isfinite(next_raw_norm) &&
           next_raw_norm <= base_raw_norm
            trial_notes = copy(notes)
            if damping < problem.solver.damping
                push!(
                    trial_notes,
                    "Backtracking accepted damping factor $(damping) after rejecting a larger trial step.",
                )
            end
            push!(
                trial_notes,
                "Accepted step reduced the frozen-weight merit function without increasing the raw residual norm.",
            )
            return (
                accepted = true,
                model = next_model,
                residual = next_residual,
                notes = trial_notes,
                rejected_trials = rejected_trials,
                damping_history = Float64[damping],
                weighted_residual_norm = next_weighted_norm,
                merit_value = next_merit,
                predicted_decrease = predicted_decrease,
                actual_decrease = actual_decrease,
                decrease_ratio = decrease_ratio,
                weighted_correction_norm = weighted_correction_norm(problem, model, damped_update),
                weighted_max_correction = weighted_max_correction(problem, model, damped_update),
                accepted_trial = trial_summary,
                best_rejected_trial = best_rejected_trial,
            )
        end

        best_rejected_trial = _best_rejected_trial(best_rejected_trial, trial_summary)
        rejected_trials += 1
        damping *= 0.5
    end

    return (
        accepted = false,
        model = model,
        residual = residual,
        notes = vcat(notes, ["Backtracking exhausted without a merit-decreasing damping factor."]),
        rejected_trials = rejected_trials,
        damping_history = Float64[],
        weighted_residual_norm = base_weighted_norm,
        merit_value = base_merit,
        predicted_decrease = NaN,
        actual_decrease = NaN,
        decrease_ratio = NaN,
        weighted_correction_norm = limited_update.weighted_correction_norm,
        weighted_max_correction = limited_update.weighted_max_correction,
        accepted_trial = nothing,
        best_rejected_trial = best_rejected_trial,
    )
end

function solve_nonlinear_system(problem::StructureProblem, initial_model::StellarModel)
    model = initial_model
    residual = assemble_structure_residual(problem, model)
    initial_residual_norm = residual_norm(residual)
    initial_weighted_residual_norm = weighted_residual_norm(problem, model, residual)
    initial_merit_value = weighted_residual_merit(problem, model, residual)
    initial_row_family_merit = row_family_merit_summary(problem, model, residual)
    residual_history = Float64[initial_residual_norm]
    weighted_residual_history = Float64[initial_weighted_residual_norm]
    merit_history = Float64[initial_merit_value]
    predicted_decrease_history = Float64[]
    actual_decrease_history = Float64[]
    decrease_ratio_history = Float64[]
    damping_history = Float64[]
    weighted_correction_norm_history = Float64[]
    weighted_max_correction_history = Float64[]
    accepted_trial_history = _ASTRA_MODULE.TrialMeritSummary[]
    best_rejected_trial = nothing
    accepted_step_count = 0
    rejected_trial_count = 0
    notes = String[
        "Initial guess uses geometry-consistent density/radius seeding, source-matched toy luminosity, and surface-anchored temperature closure.",
        "Solve boundary note: diagnostics describe the structure solve boundary now so later sensitivity rules can target the public solve entry point rather than Newton transcript details.",
    ]

    for _ in 1:problem.solver.max_newton_iterations
        current_weighted_residual_norm = last(weighted_residual_history)
        current_merit_value = last(merit_history)
        if converged_residual(problem, model, residual)
            diagnostics = build_diagnostics(
                problem,
                model,
                residual,
                initial_residual_norm,
                residual_history,
                current_weighted_residual_norm,
                weighted_residual_history,
                current_merit_value,
                merit_history,
                predicted_decrease_history,
                actual_decrease_history,
                decrease_ratio_history,
                damping_history,
                weighted_correction_norm_history,
                weighted_max_correction_history,
                accepted_trial_history,
                best_rejected_trial,
                accepted_step_count,
                rejected_trial_count,
                accepted_step_count,
                true,
                initial_row_family_merit,
                row_family_merit_summary(problem, model, residual),
                notes,
            )
            return SolveResult(model, diagnostics)
        end

        jacobian = structure_jacobian(problem, model)
        column_scale = state_scaling(problem, model)
        update = nothing
        try
            update = solve_linear_system(jacobian, -residual; column_scale = column_scale)
        catch error
            push!(
                notes,
                "Direct linear solve hit $(typeof(error)); retrying with regularized normal equations on the scaled Newton system.",
            )
        end

        accepted = false
        if update !== nothing && all(isfinite, update)
            trial_step = _accepted_trial_step(problem, model, residual, jacobian, update)
            append!(notes, trial_step.notes)
            rejected_trial_count += trial_step.rejected_trials
            best_rejected_trial = _best_rejected_trial(
                best_rejected_trial,
                trial_step.best_rejected_trial,
            )
            if trial_step.accepted
                accepted_step_count += 1
                append!(damping_history, trial_step.damping_history)
                model = trial_step.model
                residual = trial_step.residual
                push!(residual_history, residual_norm(residual))
                push!(weighted_residual_history, trial_step.weighted_residual_norm)
                push!(merit_history, trial_step.merit_value)
                push!(predicted_decrease_history, trial_step.predicted_decrease)
                push!(actual_decrease_history, trial_step.actual_decrease)
                push!(decrease_ratio_history, trial_step.decrease_ratio)
                push!(
                    weighted_correction_norm_history,
                    trial_step.weighted_correction_norm,
                )
                push!(weighted_max_correction_history, trial_step.weighted_max_correction)
                push!(accepted_trial_history, trial_step.accepted_trial)
                accepted = true
            end
        elseif update !== nothing
            push!(notes, "Linear solve produced a non-finite update vector.")
        end

        if accepted
            continue
        end

        for regularization in _regularization_ladder(problem)
            push!(
                notes,
                "Retrying with regularization λ=$(regularization) in the scaled normal-equation solve.",
            )
            regularized_update = try
                solve_regularized_linear_system(
                    jacobian,
                    residual,
                    regularization;
                    column_scale = column_scale,
                )
            catch fallback_error
                push!(
                    notes,
                    "Regularized fallback at λ=$(regularization) failed with $(typeof(fallback_error)).",
                )
                continue
            end

            if !all(isfinite, regularized_update)
                push!(
                    notes,
                    "Regularized update at λ=$(regularization) produced a non-finite update vector.",
                )
                continue
            end

            trial_step = _accepted_trial_step(
                problem,
                model,
                residual,
                jacobian,
                regularized_update,
            )
            append!(notes, trial_step.notes)
            rejected_trial_count += trial_step.rejected_trials
            best_rejected_trial = _best_rejected_trial(
                best_rejected_trial,
                trial_step.best_rejected_trial,
            )
            if trial_step.accepted
                accepted_step_count += 1
                append!(damping_history, trial_step.damping_history)
                model = trial_step.model
                residual = trial_step.residual
                push!(residual_history, residual_norm(residual))
                push!(weighted_residual_history, trial_step.weighted_residual_norm)
                push!(merit_history, trial_step.merit_value)
                push!(predicted_decrease_history, trial_step.predicted_decrease)
                push!(actual_decrease_history, trial_step.actual_decrease)
                push!(decrease_ratio_history, trial_step.decrease_ratio)
                push!(
                    weighted_correction_norm_history,
                    trial_step.weighted_correction_norm,
                )
                push!(weighted_max_correction_history, trial_step.weighted_max_correction)
                push!(accepted_trial_history, trial_step.accepted_trial)
                accepted = true
                break
            end
        end

        if !accepted
            current_weighted_residual_norm = last(weighted_residual_history)
            current_merit_value = last(merit_history)
            diagnostics = build_diagnostics(
                problem,
                model,
                residual,
                initial_residual_norm,
                residual_history,
                current_weighted_residual_norm,
                weighted_residual_history,
                current_merit_value,
                merit_history,
                predicted_decrease_history,
                actual_decrease_history,
                decrease_ratio_history,
                damping_history,
                weighted_correction_norm_history,
                weighted_max_correction_history,
                accepted_trial_history,
                best_rejected_trial,
                accepted_step_count,
                rejected_trial_count,
                accepted_step_count,
                false,
                initial_row_family_merit,
                row_family_merit_summary(problem, model, residual),
                notes,
            )
            return SolveResult(model, diagnostics)
        end
    end

    current_weighted_residual_norm = last(weighted_residual_history)
    current_merit_value = last(merit_history)
    diagnostics = build_diagnostics(
        problem,
        model,
        residual,
        initial_residual_norm,
        residual_history,
        current_weighted_residual_norm,
        weighted_residual_history,
        current_merit_value,
        merit_history,
        predicted_decrease_history,
        actual_decrease_history,
        decrease_ratio_history,
        damping_history,
        weighted_correction_norm_history,
        weighted_max_correction_history,
        accepted_trial_history,
        best_rejected_trial,
        accepted_step_count,
        rejected_trial_count,
        accepted_step_count,
        false,
        initial_row_family_merit,
        row_family_merit_summary(problem, model, residual),
        notes,
    )
    return SolveResult(model, diagnostics)
end
