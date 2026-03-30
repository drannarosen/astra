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

function _accepted_trial_step(
    problem::StructureProblem,
    model::StellarModel,
    residual::AbstractVector{<:Real},
    update::AbstractVector{<:Real},
)
    base_vector = pack_state(model.structure)
    base_raw_norm = residual_norm(residual)
    base_row_weights = residual_row_weights(problem, model)
    base_weighted_norm = weighted_residual_norm(residual, base_row_weights)
    limited_update = limit_weighted_correction(problem, model, update)
    damping = problem.solver.damping
    rejected_trials = 0
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

        if isfinite(next_weighted_norm) &&
           next_weighted_norm < base_weighted_norm &&
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
                "Accepted step reduced the weighted residual metric without increasing the raw residual norm.",
            )
            return (
                accepted = true,
                model = next_model,
                residual = next_residual,
                notes = trial_notes,
                rejected_trials = rejected_trials,
                damping_history = Float64[damping],
                weighted_residual_norm = next_weighted_norm,
                weighted_correction_norm = weighted_correction_norm(problem, model, damped_update),
                weighted_max_correction = weighted_max_correction(problem, model, damped_update),
            )
        end

        rejected_trials += 1
        damping *= 0.5
    end

    return (
        accepted = false,
        model = model,
        residual = residual,
        notes = vcat(notes, ["Backtracking exhausted without an acceptable damping factor."]),
        rejected_trials = rejected_trials,
        damping_history = Float64[],
        weighted_residual_norm = base_weighted_norm,
        weighted_correction_norm = limited_update.weighted_correction_norm,
        weighted_max_correction = limited_update.weighted_max_correction,
    )
end

function solve_nonlinear_system(problem::StructureProblem, initial_model::StellarModel)
    model = initial_model
    residual = assemble_structure_residual(problem, model)
    initial_residual_norm = residual_norm(residual)
    initial_weighted_residual_norm = weighted_residual_norm(problem, model, residual)
    residual_history = Float64[initial_residual_norm]
    weighted_residual_history = Float64[initial_weighted_residual_norm]
    damping_history = Float64[]
    weighted_correction_norm_history = Float64[]
    weighted_max_correction_history = Float64[]
    accepted_step_count = 0
    rejected_trial_count = 0
    notes = String[
        "Initial guess uses geometry-consistent density/radius seeding, source-matched toy luminosity, and surface-anchored temperature closure.",
        "Solve boundary note: diagnostics describe the structure solve boundary now so later sensitivity rules can target the public solve entry point rather than Newton transcript details.",
    ]

    for _ in 1:problem.solver.max_newton_iterations
        current_weighted_residual_norm = weighted_residual_norm(problem, model, residual)
        if converged_residual(problem, model, residual)
            diagnostics = build_diagnostics(
                problem,
                model,
                residual,
                initial_residual_norm,
                residual_history,
                current_weighted_residual_norm,
                weighted_residual_history,
                damping_history,
                weighted_correction_norm_history,
                weighted_max_correction_history,
                accepted_step_count,
                rejected_trial_count,
                accepted_step_count,
                true,
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
            trial_step = _accepted_trial_step(problem, model, residual, update)
            append!(notes, trial_step.notes)
            rejected_trial_count += trial_step.rejected_trials
            if trial_step.accepted
                accepted_step_count += 1
                append!(damping_history, trial_step.damping_history)
                model = trial_step.model
                residual = trial_step.residual
                push!(residual_history, residual_norm(residual))
                push!(weighted_residual_history, trial_step.weighted_residual_norm)
                push!(
                    weighted_correction_norm_history,
                    trial_step.weighted_correction_norm,
                )
                push!(weighted_max_correction_history, trial_step.weighted_max_correction)
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

            trial_step = _accepted_trial_step(problem, model, residual, regularized_update)
            append!(notes, trial_step.notes)
            rejected_trial_count += trial_step.rejected_trials
            if trial_step.accepted
                accepted_step_count += 1
                append!(damping_history, trial_step.damping_history)
                model = trial_step.model
                residual = trial_step.residual
                push!(residual_history, residual_norm(residual))
                push!(weighted_residual_history, trial_step.weighted_residual_norm)
                push!(
                    weighted_correction_norm_history,
                    trial_step.weighted_correction_norm,
                )
                push!(weighted_max_correction_history, trial_step.weighted_max_correction)
                accepted = true
                break
            end
        end

        if !accepted
            current_weighted_residual_norm = weighted_residual_norm(problem, model, residual)
            diagnostics = build_diagnostics(
                problem,
                model,
                residual,
                initial_residual_norm,
                residual_history,
                current_weighted_residual_norm,
                weighted_residual_history,
                damping_history,
                weighted_correction_norm_history,
                weighted_max_correction_history,
                accepted_step_count,
                rejected_trial_count,
                accepted_step_count,
                false,
                notes,
            )
            return SolveResult(model, diagnostics)
        end
    end

    current_weighted_residual_norm = weighted_residual_norm(problem, model, residual)
    diagnostics = build_diagnostics(
        problem,
        model,
        residual,
        initial_residual_norm,
        residual_history,
        current_weighted_residual_norm,
        weighted_residual_history,
        damping_history,
        weighted_correction_norm_history,
        weighted_max_correction_history,
        accepted_step_count,
        rejected_trial_count,
        accepted_step_count,
        false,
        notes,
    )
    return SolveResult(model, diagnostics)
end
