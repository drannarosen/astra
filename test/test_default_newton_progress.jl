@testset "default newton progress" begin
    problem = ASTRA.build_toy_problem(n_cells = 12)
    guess = initialize_state(problem)
    initial_residual = ASTRA.residual_norm(ASTRA.assemble_structure_residual(problem, guess))
    initial_weighted_residual = ASTRA.Solvers.weighted_residual_norm(
        problem,
        guess,
        ASTRA.assemble_structure_residual(problem, guess),
    )
    initial_merit = ASTRA.Solvers.weighted_residual_merit(
        problem,
        guess,
        ASTRA.assemble_structure_residual(problem, guess),
    )

    result = solve_structure(problem; state = guess)
    final_residual = ASTRA.assemble_structure_residual(problem, result.state)
    final_row_weights = ASTRA.Solvers.residual_row_weights(problem, result.state)

    @test result.diagnostics.accepted_step_count >= 1
    @test result.diagnostics.iterations >= 1
    @test length(result.diagnostics.residual_history) >= 2
    @test length(result.diagnostics.weighted_residual_history) >= 2
    @test all(isfinite, result.diagnostics.residual_history)
    @test all(isfinite, result.diagnostics.weighted_residual_history)
    @test isfinite(result.diagnostics.residual_norm)
    @test isfinite(result.diagnostics.weighted_residual_norm)
    @test all(result.diagnostics.predicted_decrease_history .> 0.0)
    @test all(result.diagnostics.actual_decrease_history .> 0.0)
    @test all(isfinite, result.diagnostics.decrease_ratio_history)
    @test all(diff(result.diagnostics.residual_history) .<= 0.0)
    @test all(
        trial -> trial.merit_value <= trial.armijo_target,
        result.diagnostics.accepted_trial_history,
    )
    @test all(
        trial -> isapprox(trial.row_family_merit.total, trial.merit_value; rtol = 1e-12),
        result.diagnostics.accepted_trial_history,
    )
    @test result.diagnostics.weighted_residual_norm <= 0.999 * initial_weighted_residual
    @test result.diagnostics.weighted_residual_norm ≈
          ASTRA.Solvers.weighted_residual_norm(final_residual, final_row_weights) rtol = 1e-12
    @test result.diagnostics.merit_value ≈
          ASTRA.Solvers.weighted_residual_merit(final_residual, final_row_weights) rtol = 1e-12
    @test result.diagnostics.final_row_family_merit.total ≈
          result.diagnostics.merit_value rtol = 1e-12
    @test result.diagnostics.merit_value < initial_merit
    @test result.diagnostics.residual_norm <= initial_residual
    @test any(
        note -> occursin("atmosphere boundary", lowercase(note)),
        result.diagnostics.notes,
    )
    @test any(
        note -> occursin("accepted", lowercase(note)) ||
            occursin("backtracking", lowercase(note)) ||
            occursin("weighted", lowercase(note)),
        result.diagnostics.notes,
    )
end
