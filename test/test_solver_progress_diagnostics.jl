using Random

function _capped_exit_progress_fixture()
    problem = ASTRA.build_toy_problem(n_cells = 6)
    solver = ASTRA.SolverConfig(max_newton_iterations = 1)
    capped_problem = ASTRA.StructureProblem(
        problem.formulation,
        problem.parameters,
        problem.composition,
        problem.grid,
        problem.microphysics,
        solver,
    )
    base_state = initialize_state(capped_problem)
    base_vector = ASTRA.pack_state(base_state.structure)

    for amplitude in (1.0e-6, 1.0e-5, 1.0e-4, 1.0e-3)
        Random.seed!(42)
        for _ in 1:256
            perturbed_vector =
                base_vector .+ amplitude .* randn(length(base_vector)) .* max.(abs.(base_vector), 1.0)
            perturbed_structure = ASTRA.unpack_state(base_state.structure, perturbed_vector)
            state = ASTRA.StellarModel(
                perturbed_structure,
                base_state.composition,
                base_state.evolution,
            )
            result = solve_structure(capped_problem; state = state)
            if result.diagnostics.accepted_step_count == capped_problem.solver.max_newton_iterations
                return capped_problem, state
            end
        end
    end

    error("Unable to find a capped one-step Newton-progress fixture.")
end

function _weighted_history_consistency_fixture()
    problem = ASTRA.build_toy_problem(n_cells = 12)
    base_state = initialize_state(problem)
    base_vector = ASTRA.pack_state(base_state.structure)

    for amplitude in (1.0e-6, 1.0e-5, 1.0e-4, 1.0e-3, 1.0e-2)
        Random.seed!(1)
        for _ in 1:100
            perturbed_vector =
                base_vector .+ amplitude .* randn(length(base_vector)) .* max.(abs.(base_vector), 1.0)
            perturbed_structure = ASTRA.unpack_state(base_state.structure, perturbed_vector)
            state = ASTRA.StellarModel(
                perturbed_structure,
                base_state.composition,
                base_state.evolution,
            )
            result = solve_structure(problem; state = state)
            if result.diagnostics.accepted_step_count > 0
                recomputed_weighted_residual = ASTRA.Solvers.weighted_residual_norm(
                    problem,
                    result.state,
                    ASTRA.assemble_structure_residual(problem, result.state),
                )
                if result.diagnostics.weighted_residual_history[end] != recomputed_weighted_residual
                    return problem, state, result
                end
            end
        end
    end

    error("Unable to find a weighted-history mismatch fixture.")
end

@testset "solver progress diagnostics" begin
    problem = ASTRA.build_toy_problem(n_cells = 12)
    guess = initialize_state(problem)
    initial_residual = ASTRA.residual_norm(ASTRA.assemble_structure_residual(problem, guess))
    initial_merit = ASTRA.Solvers.weighted_residual_merit(
        ASTRA.assemble_structure_residual(problem, guess),
        ASTRA.Solvers.residual_row_weights(problem, guess),
    )
    surface_rows = ASTRA.structure_surface_row_range(problem.grid.n_cells)
    surface_weights = ASTRA.Solvers.residual_row_weights(problem, guess)[surface_rows]
    surface_pressure_dyn_cm2 = ASTRA.cell_eos_state(problem, guess, problem.grid.n_cells).pressure_dyn_cm2
    surface_match_pressure_dyn_cm2 = ASTRA.outer_match_pressure_dyn_cm2(problem, guess)

    result = solve_structure(problem; state = guess)
    final_residual = ASTRA.assemble_structure_residual(problem, result.state)
    final_row_weights = ASTRA.Solvers.residual_row_weights(problem, result.state)
    final_weighted_residual = ASTRA.Solvers.weighted_residual_norm(
        final_residual,
        final_row_weights,
    )
    final_merit = ASTRA.Solvers.weighted_residual_merit(final_residual, final_row_weights)

    @test surface_weights[3] == 1.0
    @test surface_weights[4] == 1.0
    @test result.diagnostics.initial_residual_norm ≈ initial_residual
    @test !isempty(result.diagnostics.residual_history)
    @test !isempty(result.diagnostics.weighted_residual_history)
    @test !isempty(result.diagnostics.merit_history)
    @test first(result.diagnostics.residual_history) ≈ initial_residual
    @test last(result.diagnostics.residual_history) ≈ result.diagnostics.residual_norm
    @test first(result.diagnostics.weighted_residual_history) ≈
          ASTRA.Solvers.weighted_residual_norm(
              problem,
              guess,
              ASTRA.assemble_structure_residual(problem, guess),
          )
    @test result.diagnostics.weighted_residual_norm ≈ final_weighted_residual rtol = 1e-12
    @test first(result.diagnostics.merit_history) ≈ initial_merit
    @test result.diagnostics.merit_value ≈ final_merit rtol = 1e-12
    @test result.diagnostics.initial_row_family_merit.total ≈
          first(result.diagnostics.merit_history)
    @test result.diagnostics.final_row_family_merit.total ≈ final_merit rtol = 1e-12
    @test result.diagnostics.initial_row_family_merit.dominant_family in
          (:center, :geometry, :hydrostatic, :luminosity, :interior_transport, :outer_transport, :surface)
    @test result.diagnostics.final_row_family_merit.dominant_family in
          (:center, :geometry, :hydrostatic, :luminosity, :interior_transport, :outer_transport, :surface)
    @test result.diagnostics.accepted_step_count >= 0
    @test result.diagnostics.rejected_trial_count >= 0
    @test length(result.diagnostics.damping_history) == result.diagnostics.accepted_step_count
    @test length(result.diagnostics.weighted_correction_norm_history) ==
          result.diagnostics.accepted_step_count
    @test length(result.diagnostics.weighted_max_correction_history) ==
          result.diagnostics.accepted_step_count
    @test length(result.diagnostics.predicted_decrease_history) ==
          result.diagnostics.accepted_step_count
    @test length(result.diagnostics.actual_decrease_history) ==
          result.diagnostics.accepted_step_count
    @test length(result.diagnostics.decrease_ratio_history) ==
          result.diagnostics.accepted_step_count
    @test length(result.diagnostics.accepted_trial_history) ==
          result.diagnostics.accepted_step_count
    @test all(0.0 < damping <= problem.solver.damping for damping in result.diagnostics.damping_history)
    @test all(
        0.0 <= correction <= 1.0 + 1.0e-12 for
        correction in result.diagnostics.weighted_correction_norm_history
    )
    @test all(
        0.0 <= correction <= 1.0 + 1.0e-12 for
        correction in result.diagnostics.weighted_max_correction_history
    )

    if !isempty(result.diagnostics.accepted_trial_history)
        accepted_trial = result.diagnostics.accepted_trial_history[end]
        @test accepted_trial.predicted_decrease > 0.0
        @test accepted_trial.actual_decrease > 0.0
        @test isfinite(accepted_trial.decrease_ratio)
        @test isfinite(accepted_trial.armijo_target)
        @test accepted_trial.row_family_merit.total ≈ accepted_trial.merit_value rtol = 1e-12
        @test accepted_trial.row_family_merit.dominant_family in
              (:center, :geometry, :hydrostatic, :luminosity, :interior_transport, :outer_transport, :surface)
        @test accepted_trial.transport_hotspot.present
        @test accepted_trial.outer_boundary.present
        @test isfinite(accepted_trial.outer_boundary.temperature_contract_log_gap)
        @test accepted_trial.outer_boundary.pressure_contract_log_gap ≈ 0.0 atol = 1.0e-12
        @test accepted_trial.transport_hotspot.cell_index in 1:(problem.grid.n_cells - 1)
        @test accepted_trial.transport_hotspot.location in (:interior, :outer)
        @test accepted_trial.transport_hotspot.weighted_contribution ≈
              accepted_trial.transport_hotspot.row_weight * accepted_trial.transport_hotspot.raw_residual
        @test accepted_trial.transport_hotspot.raw_residual ≈
              accepted_trial.transport_hotspot.delta_log_temperature -
              accepted_trial.transport_hotspot.gradient_term
        @test accepted_trial.transport_hotspot.gradient_term ≈
              accepted_trial.transport_hotspot.nabla_transport *
              accepted_trial.transport_hotspot.delta_log_pressure
    end

    if result.diagnostics.rejected_trial_count > 0
        @test result.diagnostics.best_rejected_trial !== nothing
        rejected_trial = result.diagnostics.best_rejected_trial
        @test rejected_trial.predicted_decrease > 0.0 || isnan(rejected_trial.decrease_ratio)
        @test rejected_trial.row_family_merit.total ≈ rejected_trial.merit_value rtol = 1e-12
        @test rejected_trial.row_family_merit.dominant_family in
              (:center, :geometry, :hydrostatic, :luminosity, :interior_transport, :outer_transport, :surface)
        @test rejected_trial.transport_hotspot.present
        @test rejected_trial.outer_boundary.present
        @test rejected_trial.transport_hotspot.cell_index in 1:(problem.grid.n_cells - 1)
        @test rejected_trial.transport_hotspot.location in (:interior, :outer)
        @test rejected_trial.transport_hotspot.raw_residual ≈
              rejected_trial.transport_hotspot.delta_log_temperature -
              rejected_trial.transport_hotspot.gradient_term
    else
        @test isnothing(result.diagnostics.best_rejected_trial)
    end

    if !result.diagnostics.converged && result.diagnostics.accepted_step_count == 0
        @test result.diagnostics.rejected_trial_count > 0
        @test any(
            note -> occursin("backtracking exhausted", lowercase(note)) ||
                occursin("no residual-reducing trial step", lowercase(note)),
            result.diagnostics.notes,
        )
    end

    capped_problem, capped_state = _capped_exit_progress_fixture()
    capped_initial_residual = ASTRA.residual_norm(
        ASTRA.assemble_structure_residual(capped_problem, capped_state),
    )
    capped_result = solve_structure(capped_problem; state = capped_state)

    @test !capped_result.diagnostics.converged
    @test capped_result.diagnostics.accepted_step_count ==
          capped_problem.solver.max_newton_iterations
    @test capped_result.diagnostics.iterations == capped_problem.solver.max_newton_iterations
    @test capped_result.diagnostics.iterations == capped_result.diagnostics.accepted_step_count
    @test length(capped_result.diagnostics.residual_history) ==
          capped_result.diagnostics.iterations + 1
    @test length(capped_result.diagnostics.weighted_residual_history) ==
          capped_result.diagnostics.iterations + 1
    @test length(capped_result.diagnostics.merit_history) ==
          capped_result.diagnostics.iterations + 1
    @test capped_result.diagnostics.initial_residual_norm ≈ capped_initial_residual
    @test first(capped_result.diagnostics.residual_history) ≈ capped_initial_residual
    @test last(capped_result.diagnostics.residual_history) ≈
          capped_result.diagnostics.residual_norm
    capped_final_residual = ASTRA.assemble_structure_residual(capped_problem, capped_result.state)
    capped_final_row_weights = ASTRA.Solvers.residual_row_weights(
        capped_problem,
        capped_result.state,
    )
    @test capped_result.diagnostics.weighted_residual_norm ≈
          ASTRA.Solvers.weighted_residual_norm(
              capped_final_residual,
              capped_final_row_weights,
          ) rtol = 1e-12
    @test capped_result.diagnostics.merit_value ≈
          ASTRA.Solvers.weighted_residual_merit(
              capped_final_residual,
              capped_final_row_weights,
          ) rtol = 1e-12

    mismatch_problem, mismatch_state, mismatch_result = _weighted_history_consistency_fixture()
    @test mismatch_result.diagnostics.accepted_step_count > 0
    mismatch_final_residual = ASTRA.assemble_structure_residual(
        mismatch_problem,
        mismatch_result.state,
    )
    mismatch_final_row_weights = ASTRA.Solvers.residual_row_weights(
        mismatch_problem,
        mismatch_result.state,
    )
    @test mismatch_result.diagnostics.weighted_residual_norm ≈
          ASTRA.Solvers.weighted_residual_norm(
              mismatch_final_residual,
              mismatch_final_row_weights,
          ) rtol = 1e-12
    @test mismatch_result.diagnostics.merit_value ≈
          ASTRA.Solvers.weighted_residual_merit(
              mismatch_final_residual,
              mismatch_final_row_weights,
          ) rtol = 1e-12
    @test mismatch_result.diagnostics.final_row_family_merit.total ≈
          mismatch_result.diagnostics.merit_value rtol = 1e-12
    @test mismatch_result.diagnostics.weighted_residual_history[end] !=
          mismatch_result.diagnostics.weighted_residual_norm
    @test mismatch_result.diagnostics.merit_history[end] !=
          mismatch_result.diagnostics.merit_value
end
