@testset "merit globalization acceptance" begin
    problem = ASTRA.build_toy_problem(n_cells = 12)
    guess = ASTRA.initialize_state(problem)
    initial_residual = ASTRA.assemble_structure_residual(problem, guess)
    initial_merit = ASTRA.Solvers.weighted_residual_merit(
        initial_residual,
        ASTRA.Solvers.residual_row_weights(problem, guess),
    )

    result = ASTRA.solve_structure(problem; state = guess)

    @test result.diagnostics.accepted_step_count >= 1
    @test all(
        trial -> trial.merit_value <= trial.armijo_target,
        result.diagnostics.accepted_trial_history,
    )
    @test all(diff(result.diagnostics.residual_history) .<= 0.0)
    @test all(result.diagnostics.predicted_decrease_history .> 0.0)
    @test all(result.diagnostics.actual_decrease_history .> 0.0)
    @test result.diagnostics.merit_value < initial_merit
    @test result.diagnostics.residual_norm <= ASTRA.residual_norm(initial_residual)
    @test any(
        note -> occursin("frozen-weight merit function", lowercase(note)),
        result.diagnostics.notes,
    )
end
