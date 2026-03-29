function _regularized_linear_update(
    jacobian::AbstractMatrix{<:Real},
    residual::AbstractVector{<:Real},
    regularization::Real,
)
    normal_matrix = jacobian' * jacobian + Float64(regularization) * I
    return normal_matrix \ (-(jacobian' * residual))
end

function _accepted_trial_step(
    problem::StructureProblem,
    model::StellarModel,
    residual::AbstractVector{<:Real},
    update::AbstractVector{<:Real},
)
    base_vector = pack_state(model.structure)
    base_norm = residual_norm(residual)
    damping = problem.solver.damping

    while damping >= problem.solver.minimum_damping
        next_vector = base_vector .+ damping .* update
        next_structure = unpack_state(model.structure, next_vector)
        next_model = StellarModel(next_structure, model.composition, model.evolution)
        next_residual = assemble_structure_residual(problem, next_model)
        next_norm = residual_norm(next_residual)

        if isfinite(next_norm) && next_norm < base_norm
            notes = damping < problem.solver.damping ? [
                "Backtracking accepted damping factor $(damping) after rejecting a larger trial step.",
            ] : String[]
            return (model = next_model, residual = next_residual, notes = notes)
        end

        damping *= 0.5
    end

    return nothing
end

function solve_nonlinear_system(problem::StructureProblem, initial_model::StellarModel)
    model = initial_model
    residual = assemble_structure_residual(problem, model)
    notes = String[
        "Initial guess uses geometry-consistent density/radius seeding, source-matched toy luminosity, and surface-anchored temperature closure.",
        "Solve boundary note: diagnostics describe the structure solve boundary now so later sensitivity rules can target the public solve entry point rather than Newton transcript details.",
    ]

    for iteration in 0:problem.solver.max_newton_iterations
        if converged_residual(problem, residual)
            diagnostics = build_diagnostics(problem, model, residual, iteration, true, notes)
            return SolveResult(model, diagnostics)
        end

        jacobian = structure_jacobian(problem, model)
        update = try
            solve_linear_system(jacobian, -residual)
        catch error
            try
                push!(
                    notes,
                    "Direct linear solve hit $(typeof(error)); retrying with regularized normal equations.",
                )
                _regularized_linear_update(
                    jacobian,
                    residual,
                    problem.solver.linear_regularization,
                )
            catch fallback_error
                diagnostics = build_diagnostics(
                    problem,
                    model,
                    residual,
                    iteration,
                    false,
                    vcat(
                        notes,
                        ["Regularized fallback failed with $(typeof(fallback_error))."],
                    ),
                )
                return SolveResult(model, diagnostics)
            end
        end

        if !all(isfinite, update)
            diagnostics = build_diagnostics(
                problem,
                model,
                residual,
                iteration,
                false,
                vcat(notes, ["Linear solve produced a non-finite update vector."]),
            )
            return SolveResult(model, diagnostics)
        end

        trial_step = _accepted_trial_step(problem, model, residual, update)
        if isnothing(trial_step)
            diagnostics = build_diagnostics(
                problem,
                model,
                residual,
                iteration,
                false,
                vcat(
                    notes,
                    ["No residual-reducing trial step was found down to damping factor $(problem.solver.minimum_damping)."],
                ),
            )
            return SolveResult(model, diagnostics)
        end

        append!(notes, trial_step.notes)
        model = trial_step.model
        residual = trial_step.residual
    end

    diagnostics = build_diagnostics(
        problem,
        model,
        residual,
        problem.solver.max_newton_iterations,
        false,
        notes,
    )
    return SolveResult(model, diagnostics)
end
