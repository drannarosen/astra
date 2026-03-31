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
    accepted_dominant_surface_family = isempty(diagnostics.accepted_trial_history) ?
        nothing :
        diagnostics.accepted_trial_history[end].row_family_merit.dominant_surface_family
    accepted_outer_boundary = isempty(diagnostics.accepted_trial_history) ?
        nothing :
        diagnostics.accepted_trial_history[end].outer_boundary
    accepted_transport_hotspot = isempty(diagnostics.accepted_trial_history) ?
        nothing :
        diagnostics.accepted_trial_history[end].transport_hotspot
    best_rejected_dominant_surface_family = isnothing(diagnostics.best_rejected_trial) ?
        nothing :
        diagnostics.best_rejected_trial.row_family_merit.dominant_surface_family
    best_rejected_outer_boundary = isnothing(diagnostics.best_rejected_trial) ?
        nothing :
        diagnostics.best_rejected_trial.outer_boundary
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
        accepted_dominant_surface_family,
        accepted_outer_boundary,
        accepted_transport_hotspot,
        diagnostics.best_rejected_trial,
        best_rejected_dominant_surface_family,
        best_rejected_outer_boundary,
        isnothing(diagnostics.best_rejected_trial) ? nothing : diagnostics.best_rejected_trial.transport_hotspot,
        used_regularized_fallback,
        diagnostics.initial_residual_norm,
        diagnostics.weighted_residual_history[1],
        diagnostics.merit_history[1],
        diagnostics.initial_row_family_merit.dominant_family,
        diagnostics.initial_row_family_merit.dominant_surface_family,
    )
end

function _armijo_merit_validation_payload_path(
    output_dir::AbstractString,
    fixture_label::AbstractString,
)
    return joinpath(output_dir, "$(fixture_label).toml")
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
    println(io, prefix * ".interior_transport = ", repr(summary.interior_transport))
    println(io, prefix * ".outer_transport = ", repr(summary.outer_transport))
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

function _write_armijo_merit_validation_transport_hotspot_summary(
    io::IO,
    prefix::AbstractString,
    hotspot::TransportHotspotSummary,
)
    println(io, prefix * ".present = ", _format_armijo_merit_validation_scalar(hotspot.present))
    println(io, prefix * ".cell_index = ", hotspot.cell_index)
    println(io, prefix * ".location = ", _format_armijo_merit_validation_scalar(hotspot.location))
    println(io, prefix * ".row_index = ", hotspot.row_index)
    println(io, prefix * ".raw_residual = ", repr(hotspot.raw_residual))
    println(io, prefix * ".row_weight = ", repr(hotspot.row_weight))
    println(io, prefix * ".weighted_contribution = ", repr(hotspot.weighted_contribution))
    println(io, prefix * ".delta_log_temperature = ", repr(hotspot.delta_log_temperature))
    println(io, prefix * ".delta_log_pressure = ", repr(hotspot.delta_log_pressure))
    println(io, prefix * ".nabla_transport = ", repr(hotspot.nabla_transport))
    println(io, prefix * ".gradient_term = ", repr(hotspot.gradient_term))
end

function _write_armijo_merit_validation_outer_boundary_summary(
    io::IO,
    prefix::AbstractString,
    summary::OuterBoundaryRowSummary,
)
    println(io, prefix * ".present = ", _format_armijo_merit_validation_scalar(summary.present))
    println(io, prefix * ".outer_transport_row_index = ", summary.outer_transport_row_index)
    println(io, prefix * ".surface_temperature_row_index = ", summary.surface_temperature_row_index)
    println(io, prefix * ".surface_pressure_row_index = ", summary.surface_pressure_row_index)
    println(io, prefix * ".outer_transport_raw = ", repr(summary.outer_transport_raw))
    println(io, prefix * ".surface_temperature_raw = ", repr(summary.surface_temperature_raw))
    println(io, prefix * ".surface_pressure_raw = ", repr(summary.surface_pressure_raw))
    println(io, prefix * ".surface_pressure_ratio = ", repr(summary.surface_pressure_ratio))
    println(
        io,
        prefix * ".surface_pressure_log_mismatch = ",
        repr(summary.surface_pressure_log_mismatch),
    )
    println(
        io,
        prefix * ".outer_transport_weighted = ",
        repr(summary.outer_transport_weighted),
    )
    println(
        io,
        prefix * ".surface_temperature_weighted = ",
        repr(summary.surface_temperature_weighted),
    )
    println(
        io,
        prefix * ".surface_pressure_weighted = ",
        repr(summary.surface_pressure_weighted),
    )
    println(io, prefix * ".surface_temperature_k = ", repr(summary.surface_temperature_k))
    println(
        io,
        prefix * ".photospheric_face_temperature_k = ",
        repr(summary.photospheric_face_temperature_k),
    )
    println(io, prefix * ".match_temperature_k = ", repr(summary.match_temperature_k))
    println(
        io,
        prefix * ".transport_temperature_offset_k = ",
        repr(summary.transport_temperature_offset_k),
    )
    println(
        io,
        prefix * ".surface_to_photosphere_log_gap = ",
        repr(summary.surface_to_photosphere_log_gap),
    )
    println(
        io,
        prefix * ".match_to_photosphere_log_gap = ",
        repr(summary.match_to_photosphere_log_gap),
    )
    println(
        io,
        prefix * ".surface_to_match_log_gap = ",
        repr(summary.surface_to_match_log_gap),
    )
    println(
        io,
        prefix * ".transport_temperature_offset_fraction = ",
        repr(summary.transport_temperature_offset_fraction),
    )
    println(
        io,
        prefix * ".photospheric_face_pressure_dyn_cm2 = ",
        repr(summary.photospheric_face_pressure_dyn_cm2),
    )
    println(
        io,
        prefix * ".match_pressure_dyn_cm2 = ",
        repr(summary.match_pressure_dyn_cm2),
    )
    println(
        io,
        prefix * ".current_match_temperature_k = ",
        repr(summary.current_match_temperature_k),
    )
    println(
        io,
        prefix * ".fitting_point_temperature_k = ",
        repr(summary.fitting_point_temperature_k),
    )
    println(
        io,
        prefix * ".temperature_contract_log_gap = ",
        repr(summary.temperature_contract_log_gap),
    )
    println(
        io,
        prefix * ".current_match_pressure_dyn_cm2 = ",
        repr(summary.current_match_pressure_dyn_cm2),
    )
    println(
        io,
        prefix * ".fitting_point_pressure_dyn_cm2 = ",
        repr(summary.fitting_point_pressure_dyn_cm2),
    )
    println(
        io,
        prefix * ".pressure_contract_log_gap = ",
        repr(summary.pressure_contract_log_gap),
    )
    println(io, prefix * ".surface_pressure_dyn_cm2 = ", repr(summary.surface_pressure_dyn_cm2))
    println(
        io,
        prefix * ".hydrostatic_pressure_offset_dyn_cm2 = ",
        repr(summary.hydrostatic_pressure_offset_dyn_cm2),
    )
    println(
        io,
        prefix * ".pressure_surface_to_photosphere_log_gap = ",
        repr(summary.pressure_surface_to_photosphere_log_gap),
    )
    println(
        io,
        prefix * ".pressure_match_to_photosphere_log_gap = ",
        repr(summary.pressure_match_to_photosphere_log_gap),
    )
    println(
        io,
        prefix * ".pressure_surface_to_match_log_gap = ",
        repr(summary.pressure_surface_to_match_log_gap),
    )
    println(
        io,
        prefix * ".hydrostatic_pressure_offset_fraction = ",
        repr(summary.hydrostatic_pressure_offset_fraction),
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
    println(
        io,
        "accepted_dominant_surface_family = ",
        _format_armijo_merit_validation_scalar(payload.accepted_dominant_surface_family),
    )
    println(
        io,
        "accepted_transport_dominant_family = ",
        _format_armijo_merit_validation_scalar(
            _armijo_merit_validation_transport_family(payload.accepted_dominant_family),
        ),
    )
    if payload.accepted_outer_boundary === nothing
        println(io, "accepted_outer_boundary.present = false")
    else
        _write_armijo_merit_validation_outer_boundary_summary(
            io,
            "accepted_outer_boundary",
            payload.accepted_outer_boundary,
        )
    end
    if payload.accepted_transport_hotspot === nothing
        println(io, "accepted_transport_hotspot.present = false")
    else
        _write_armijo_merit_validation_transport_hotspot_summary(
            io,
            "accepted_transport_hotspot",
            payload.accepted_transport_hotspot,
        )
    end

    if payload.best_rejected_trial === nothing
        println(io, "best_rejected_trial.present = false")
    else
        _write_armijo_merit_validation_trial_summary(io, payload.best_rejected_trial)
    end
    println(
        io,
        "best_rejected_dominant_surface_family = ",
        _format_armijo_merit_validation_scalar(payload.best_rejected_dominant_surface_family),
    )
    if payload.best_rejected_outer_boundary === nothing
        println(io, "best_rejected_outer_boundary.present = false")
    else
        _write_armijo_merit_validation_outer_boundary_summary(
            io,
            "best_rejected_outer_boundary",
            payload.best_rejected_outer_boundary,
        )
    end
    println(
        io,
        "best_rejected_transport_dominant_family = ",
        _format_armijo_merit_validation_scalar(
            _armijo_merit_validation_transport_family(
                _armijo_merit_validation_best_rejected_family(payload),
            ),
        ),
    )
    if payload.best_rejected_transport_hotspot === nothing
        println(io, "best_rejected_transport_hotspot.present = false")
    else
        _write_armijo_merit_validation_transport_hotspot_summary(
            io,
            "best_rejected_transport_hotspot",
            payload.best_rejected_transport_hotspot,
        )
    end

    println(
        io,
        "used_regularized_fallback = ",
        _format_armijo_merit_validation_scalar(payload.used_regularized_fallback),
    )
end

function _armijo_merit_validation_best_rejected_family(
    payload::ArmijoMeritValidationPayload,
)
    payload.best_rejected_trial === nothing && return nothing
    return payload.best_rejected_trial.row_family_merit.dominant_family
end

function _armijo_merit_validation_transport_family(
    family::Union{Nothing,Symbol},
)
    family in (:interior_transport, :outer_transport) || return nothing
    return family
end

function _armijo_merit_validation_outer_boundary_dominant_family(
    summary::Union{Nothing,OuterBoundaryRowSummary},
)
    summary === nothing && return nothing
    contributions = abs.(
        (
            summary.outer_transport_weighted,
            summary.surface_temperature_weighted,
            summary.surface_pressure_weighted,
        ),
    )
    names = (:outer_transport, :surface_temperature, :surface_pressure)
    return names[argmax(contributions)]
end

function _armijo_merit_validation_surface_pressure_bridge_dominant(
    summary::Union{Nothing,OuterBoundaryRowSummary},
)
    return _armijo_merit_validation_outer_boundary_dominant_family(summary) == :surface_pressure
end

function _armijo_merit_validation_amplitude_label(amplitude::Real)
    return replace(repr(Float64(amplitude)), "1.0e-" => "1e-")
end

function _armijo_merit_validation_perturbation(
    base_vector::AbstractVector{<:Real},
    amplitude::Real,
    case_index::Int,
)
    scale = max.(abs.(base_vector), 1.0)
    phase = 0.2718281828459045 * case_index + log10(Float64(amplitude) + eps(Float64))
    return Float64(amplitude) .* scale .* [
        sin(phase + 0.17 * idx) + 0.5 * cos(phase - 0.11 * idx) for idx in eachindex(base_vector)
    ]
end

function _write_armijo_merit_validation_manifest_entry(io::IO, payload, payload_path)
    println(io, "payload = ", payload.fixture_label)
    println(io, "fixture_label = ", payload.fixture_label)
    println(io, "n_cells = ", payload.n_cells)
    println(io, "converged = ", _format_armijo_merit_validation_scalar(payload.converged))
    println(io, "accepted_step_count = ", payload.accepted_step_count)
    println(io, "rejected_trial_count = ", payload.rejected_trial_count)
    println(
        io,
        "final_weighted_residual_norm = ",
        repr(payload.final_weighted_residual_norm),
    )
    println(io, "final_merit = ", repr(payload.final_merit))
    println(
        io,
        "accepted_dominant_family = ",
        _format_armijo_merit_validation_scalar(payload.accepted_dominant_family),
    )
    println(
        io,
        "accepted_dominant_surface_family = ",
        _format_armijo_merit_validation_scalar(payload.accepted_dominant_surface_family),
    )
    println(
        io,
        "accepted_transport_dominant_family = ",
        _format_armijo_merit_validation_scalar(
            _armijo_merit_validation_transport_family(payload.accepted_dominant_family),
        ),
    )
    println(
        io,
        "accepted_transport_hotspot_location = ",
        _format_armijo_merit_validation_scalar(
            isnothing(payload.accepted_transport_hotspot) ? nothing : payload.accepted_transport_hotspot.location,
        ),
    )
    println(
        io,
        "accepted_transport_hotspot_cell_index = ",
        isnothing(payload.accepted_transport_hotspot) ? "nothing" : string(payload.accepted_transport_hotspot.cell_index),
    )
    println(
        io,
        "best_rejected_dominant_family = ",
        _format_armijo_merit_validation_scalar(
            _armijo_merit_validation_best_rejected_family(payload),
        ),
    )
    println(
        io,
        "best_rejected_dominant_surface_family = ",
        _format_armijo_merit_validation_scalar(payload.best_rejected_dominant_surface_family),
    )
    println(
        io,
        "best_rejected_transport_dominant_family = ",
        _format_armijo_merit_validation_scalar(
            _armijo_merit_validation_transport_family(
                _armijo_merit_validation_best_rejected_family(payload),
            ),
        ),
    )
    println(
        io,
        "best_rejected_transport_hotspot_location = ",
        _format_armijo_merit_validation_scalar(
            isnothing(payload.best_rejected_transport_hotspot) ? nothing : payload.best_rejected_transport_hotspot.location,
        ),
    )
    println(
        io,
        "best_rejected_transport_hotspot_cell_index = ",
        isnothing(payload.best_rejected_transport_hotspot) ? "nothing" : string(payload.best_rejected_transport_hotspot.cell_index),
    )
    println(
        io,
        "used_regularized_fallback = ",
        _format_armijo_merit_validation_scalar(payload.used_regularized_fallback),
    )
    println(io, "payload_path = ", payload_path)
    println(io)
end

function _try_build_armijo_merit_validation_perturbation_payload(
    problem::StructureProblem,
    base_state::StellarModel,
    amplitude::Real,
    case_index::Int;
    seed_label::AbstractString = "perturb",
    fixture_prefix::AbstractString = "",
)
    base_vector = pack_state(base_state.structure)
    perturbation = _armijo_merit_validation_perturbation(base_vector, amplitude, case_index)
    perturbed_vector = base_vector .+ perturbation
    perturbed_structure = unpack_state(base_state.structure, perturbed_vector)
    perturbed_state = StellarModel(
        perturbed_structure,
        base_state.composition,
        base_state.evolution,
    )
    result = solve_structure(problem; state = perturbed_state)
    label = "perturb-a$(_armijo_merit_validation_amplitude_label(amplitude))" *
            "-case-$(lpad(case_index, 2, '0'))"
    fixture_label = isempty(fixture_prefix) ? label : "$(fixture_prefix)-$(label)"
    return build_armijo_merit_validation_payload(
        fixture_label,
        problem,
        result;
        seed_label = String(seed_label),
    )
end

function _armijo_merit_validation_perturbation_minimum()
    return 3
end

function run_armijo_merit_validation_suite(output_dir::AbstractString)
    mkpath(output_dir)

    payload_paths = String[]
    payloads = ArmijoMeritValidationPayload[]
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
        push!(payloads, payload)
    end

    perturbation_problem = build_toy_problem(n_cells = 12)
    perturbation_state = initialize_state(perturbation_problem)
    perturbation_payloads = ArmijoMeritValidationPayload[]
    for amplitude in (1.0e-6, 1.0e-5, 1.0e-4, 1.0e-3)
        for case_index in 1:8
            payload = _try_build_armijo_merit_validation_perturbation_payload(
                perturbation_problem,
                perturbation_state,
                amplitude,
                case_index,
            )
            if payload.accepted_step_count > 0
                push!(perturbation_payloads, payload)
            end
            length(perturbation_payloads) >= 3 && break
        end
        length(perturbation_payloads) >= 3 && break
    end

    for payload in perturbation_payloads
        payload_path = _armijo_merit_validation_payload_path(output_dir, payload.fixture_label)
        open(payload_path, "w") do io
            _write_armijo_merit_validation_payload(io, payload)
        end
        push!(payload_paths, payload_path)
        push!(payloads, payload)
    end

    if length(perturbation_payloads) < _armijo_merit_validation_perturbation_minimum()
        error(
            "Armijo validation suite produced $(length(perturbation_payloads)) perturbation payloads; at least $(_armijo_merit_validation_perturbation_minimum()) are required.",
        )
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
    push!(payloads, default_payload)

    manifest_path = joinpath(output_dir, "manifest.txt")
    open(manifest_path, "w") do io
        for (payload, payload_path) in zip(payloads, payload_paths)
            _write_armijo_merit_validation_manifest_entry(io, payload, payload_path)
        end
    end

    return ArmijoMeritValidationBundle(String(manifest_path), payload_paths)
end

function run_outer_boundary_ownership_audit(output_dir::AbstractString)
    mkpath(output_dir)
    _clear_outer_boundary_ownership_audit_payloads(output_dir)

    payloads = ArmijoMeritValidationPayload[]

    default_problem = build_toy_problem(n_cells = 12)
    default_guess = initialize_state(default_problem)
    default_result = solve_structure(default_problem; state = default_guess)
    push!(
        payloads,
        build_armijo_merit_validation_payload(
            "default-12",
            default_problem,
            default_result;
            seed_label = "default",
        ),
    )

    for case_index in 1:3
        push!(
            payloads,
            _try_build_armijo_merit_validation_perturbation_payload(
                default_problem,
                default_guess,
                1.0e-6,
                case_index,
            ),
        )
    end

    payload_paths = String[]
    for payload in payloads
        payload_path = _armijo_merit_validation_payload_path(output_dir, payload.fixture_label)
        open(payload_path, "w") do io
            _write_armijo_merit_validation_payload(io, payload)
        end
        push!(payload_paths, payload_path)
    end

    manifest_path = joinpath(output_dir, "manifest.txt")
    open(manifest_path, "w") do io
        for (payload, payload_path) in zip(payloads, payload_paths)
            println(io, "fixture_label = ", payload.fixture_label)
            println(io, "payload_path = ", basename(payload_path))
            println(io)
        end
    end

    return ArmijoMeritValidationBundle(String(manifest_path), payload_paths)
end

function _write_seed_strategy_payload(io::IO, payload::ArmijoMeritValidationPayload)
    _write_armijo_merit_validation_payload(io, payload)
    println(io, "initial_residual_norm = ", repr(payload.initial_residual_norm))
    println(
        io,
        "initial_weighted_residual_norm = ",
        repr(payload.initial_weighted_residual_norm),
    )
    println(io, "initial_merit = ", repr(payload.initial_merit))
    println(
        io,
        "initial_dominant_family = ",
        _format_armijo_merit_validation_scalar(payload.initial_dominant_family),
    )
    println(
        io,
        "initial_dominant_surface_family = ",
        _format_armijo_merit_validation_scalar(payload.initial_dominant_surface_family),
    )
    println(
        io,
        "accepted_outer_boundary_dominant_family = ",
        _format_armijo_merit_validation_scalar(
            _armijo_merit_validation_outer_boundary_dominant_family(
                payload.accepted_outer_boundary,
            ),
        ),
    )
    println(
        io,
        "accepted_surface_pressure_bridge_dominant = ",
        _format_armijo_merit_validation_scalar(
            _armijo_merit_validation_surface_pressure_bridge_dominant(
                payload.accepted_outer_boundary,
            ),
        ),
    )
end

function _write_seed_strategy_manifest_entry(
    io::IO,
    payload::ArmijoMeritValidationPayload,
    payload_path::AbstractString,
)
    println(io, "payload = ", payload.fixture_label)
    println(io, "payload_path = ", payload_path)
    println(io, "seed_label = ", payload.seed_label)
    println(io, "converged = ", _format_armijo_merit_validation_scalar(payload.converged))
    println(io, "accepted_step_count = ", payload.accepted_step_count)
    println(io, "rejected_trial_count = ", payload.rejected_trial_count)
    println(io, "initial_merit = ", repr(payload.initial_merit))
    println(io, "final_merit = ", repr(payload.final_merit))
    println(
        io,
        "initial_dominant_family = ",
        _format_armijo_merit_validation_scalar(payload.initial_dominant_family),
    )
    println(
        io,
        "accepted_dominant_family = ",
        _format_armijo_merit_validation_scalar(payload.accepted_dominant_family),
    )
    println(
        io,
        "accepted_dominant_surface_family = ",
        _format_armijo_merit_validation_scalar(payload.accepted_dominant_surface_family),
    )
    println(
        io,
        "accepted_outer_boundary_dominant_family = ",
        _format_armijo_merit_validation_scalar(
            _armijo_merit_validation_outer_boundary_dominant_family(
                payload.accepted_outer_boundary,
            ),
        ),
    )
    println(
        io,
        "accepted_surface_pressure_bridge_dominant = ",
        _format_armijo_merit_validation_scalar(
            _armijo_merit_validation_surface_pressure_bridge_dominant(
                payload.accepted_outer_boundary,
            ),
        ),
    )
    println(
        io,
        "used_regularized_fallback = ",
        _format_armijo_merit_validation_scalar(payload.used_regularized_fallback),
    )
    println(io)
end

function run_seed_strategy_audit(output_dir::AbstractString)
    mkpath(output_dir)
    _clear_outer_boundary_ownership_audit_payloads(output_dir)

    problem = build_toy_problem(n_cells = 12)
    seed_builders = (
        ("bootstrap_default", _bootstrap_default_initial_state),
        ("convective_pms_like", _convective_pms_like_initial_state),
    )

    payloads = ArmijoMeritValidationPayload[]
    payload_paths = String[]
    for (seed_label, seed_builder) in seed_builders
        seed_state = seed_builder(problem)
        default_result = solve_structure(problem; state = seed_state)
        push!(
            payloads,
            build_armijo_merit_validation_payload(
                "$(seed_label)-default-12",
                problem,
                default_result;
                seed_label = seed_label,
            ),
        )
        for case_index in 1:3
            push!(
                payloads,
                _try_build_armijo_merit_validation_perturbation_payload(
                    problem,
                    seed_state,
                    1.0e-6,
                    case_index;
                    seed_label = seed_label,
                    fixture_prefix = seed_label,
                ),
            )
        end
    end

    for payload in payloads
        payload_path = _armijo_merit_validation_payload_path(output_dir, payload.fixture_label)
        open(payload_path, "w") do io
            _write_seed_strategy_payload(io, payload)
        end
        push!(payload_paths, payload_path)
    end

    manifest_path = joinpath(output_dir, "manifest.txt")
    open(manifest_path, "w") do io
        for (payload, payload_path) in zip(payloads, payload_paths)
            _write_seed_strategy_manifest_entry(io, payload, basename(payload_path))
        end
    end

    return ArmijoMeritValidationBundle(String(manifest_path), payload_paths)
end

function run_surface_owner_localization_audit(output_dir::AbstractString)
    return run_outer_boundary_ownership_audit(output_dir)
end

function run_surface_temperature_semantics_audit(output_dir::AbstractString)
    return run_surface_owner_localization_audit(output_dir)
end

function run_surface_pressure_semantics_audit(output_dir::AbstractString)
    return run_surface_owner_localization_audit(output_dir)
end

function _clear_outer_boundary_ownership_audit_payloads(output_dir::AbstractString)
    for entry in readdir(output_dir)
        if endswith(entry, ".toml") || entry == "manifest.txt"
            rm(joinpath(output_dir, entry); force = true)
        end
    end
end
