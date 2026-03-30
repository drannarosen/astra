"""
    build_armijo_merit_validation_payload(fixture_label, problem, result; seed_label)

Build a validation-only payload from a completed Armijo-controlled structure solve.
The payload copies the recorded histories and surfaces the controller evidence
needed for downstream scientific interpretation.
"""
struct ArmijoMeritValidationBundle
    manifest_path::String
    payload_paths::Vector{String}
end

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

function _armijo_merit_validation_payload_path(
    output_dir::AbstractString,
    fixture_label::AbstractString,
)
    return joinpath(output_dir, "$(fixture_label).txt")
end

function _format_armijo_merit_validation_scalar(value)
    if value === nothing
        return "nothing"
    elseif value isa Bool
        return value ? "true" : "false"
    elseif value isa Symbol
        return String(value)
    elseif value isa AbstractFloat
        return repr(Float64(value))
    else
        return string(value)
    end
end

function _format_armijo_merit_validation_float_vector(values::AbstractVector{<:Real})
    return "[" * join((repr(Float64(value)) for value in values), ", ") * "]"
end

function _write_armijo_merit_validation_row_family_summary(
    io::IO,
    prefix::AbstractString,
    summary::RowFamilyMeritSummary,
)
    println(io, prefix * ".center = ", repr(summary.center))
    println(io, prefix * ".geometry = ", repr(summary.geometry))
    println(io, prefix * ".hydrostatic = ", repr(summary.hydrostatic))
    println(io, prefix * ".luminosity = ", repr(summary.luminosity))
    println(io, prefix * ".transport = ", repr(summary.transport))
    println(io, prefix * ".surface = ", repr(summary.surface))
    println(io, prefix * ".total = ", repr(summary.total))
    println(
        io,
        prefix * ".dominant_family = ",
        _format_armijo_merit_validation_scalar(summary.dominant_family),
    )
end

function _write_armijo_merit_validation_trial_summary(
    io::IO,
    trial::TrialMeritSummary,
)
    println(io, "best_rejected_trial.present = true")
    println(io, "best_rejected_trial.damping = ", repr(trial.damping))
    println(
        io,
        "best_rejected_trial.raw_residual_norm = ",
        repr(trial.raw_residual_norm),
    )
    println(
        io,
        "best_rejected_trial.weighted_residual_norm = ",
        repr(trial.weighted_residual_norm),
    )
    println(io, "best_rejected_trial.merit_value = ", repr(trial.merit_value))
    println(io, "best_rejected_trial.armijo_target = ", repr(trial.armijo_target))
    println(
        io,
        "best_rejected_trial.predicted_decrease = ",
        repr(trial.predicted_decrease),
    )
    println(io, "best_rejected_trial.actual_decrease = ", repr(trial.actual_decrease))
    println(io, "best_rejected_trial.decrease_ratio = ", repr(trial.decrease_ratio))
    _write_armijo_merit_validation_row_family_summary(
        io,
        "best_rejected_trial.row_family_merit",
        trial.row_family_merit,
    )
end

function _write_armijo_merit_validation_payload(
    io::IO,
    payload::ArmijoMeritValidationPayload,
)
    println(io, "fixture_label = ", payload.fixture_label)
    println(io, "seed_label = ", payload.seed_label)
    println(io, "n_cells = ", payload.n_cells)
    println(io, "converged = ", _format_armijo_merit_validation_scalar(payload.converged))
    println(io, "accepted_step_count = ", payload.accepted_step_count)
    println(io, "rejected_trial_count = ", payload.rejected_trial_count)
    println(io, "final_residual_norm = ", repr(payload.final_residual_norm))
    println(
        io,
        "final_weighted_residual_norm = ",
        repr(payload.final_weighted_residual_norm),
    )
    println(io, "final_merit = ", repr(payload.final_merit))
    println(
        io,
        "predicted_decrease_history = ",
        _format_armijo_merit_validation_float_vector(payload.predicted_decrease_history),
    )
    println(
        io,
        "actual_decrease_history = ",
        _format_armijo_merit_validation_float_vector(payload.actual_decrease_history),
    )
    println(
        io,
        "decrease_ratio_history = ",
        _format_armijo_merit_validation_float_vector(payload.decrease_ratio_history),
    )
    println(
        io,
        "accepted_dominant_family = ",
        _format_armijo_merit_validation_scalar(payload.accepted_dominant_family),
    )

    if payload.best_rejected_trial === nothing
        println(io, "best_rejected_trial.present = false")
    else
        _write_armijo_merit_validation_trial_summary(io, payload.best_rejected_trial)
    end

    println(
        io,
        "used_regularized_fallback = ",
        _format_armijo_merit_validation_scalar(payload.used_regularized_fallback),
    )
end

function run_armijo_merit_validation_suite(output_dir::AbstractString)
    mkpath(output_dir)

    payload_paths = String[]
    for n_cells in (6, 8, 12, 16, 24)
        problem = build_toy_problem(n_cells = n_cells)
        guess = initialize_state(problem)
        result = solve_structure(problem; state = guess)
        payload = build_armijo_merit_validation_payload(
            "cells-$(n_cells)",
            problem,
            result;
            seed_label = "default",
        )
        payload_path = _armijo_merit_validation_payload_path(output_dir, payload.fixture_label)
        open(payload_path, "w") do io
            _write_armijo_merit_validation_payload(io, payload)
        end
        push!(payload_paths, payload_path)
    end

    default_problem = build_toy_problem(n_cells = 12)
    default_guess = initialize_state(default_problem)
    default_result = solve_structure(default_problem; state = default_guess)
    default_payload = build_armijo_merit_validation_payload(
        "default-12",
        default_problem,
        default_result;
        seed_label = "default",
    )
    default_path = _armijo_merit_validation_payload_path(output_dir, default_payload.fixture_label)
    open(default_path, "w") do io
        _write_armijo_merit_validation_payload(io, default_payload)
    end
    push!(payload_paths, default_path)

    manifest_path = joinpath(output_dir, "manifest.txt")
    open(manifest_path, "w") do io
        for payload_path in payload_paths
            println(io, payload_path)
        end
    end

    return ArmijoMeritValidationBundle(String(manifest_path), payload_paths)
end
