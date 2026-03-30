@testset "armijo merit acceptance" begin
    problem = ASTRA.build_toy_problem(n_cells = 12)
    guess = ASTRA.initialize_state(problem)
    result = ASTRA.solve_structure(problem; state = guess)

    @test result.diagnostics.accepted_step_count >= 1
    @test !isempty(result.diagnostics.accepted_trial_history)
    @test all(result.diagnostics.predicted_decrease_history .> 0.0)
    @test all(result.diagnostics.actual_decrease_history .> 0.0)
    @test all(isfinite, result.diagnostics.decrease_ratio_history)
    @test all(
        trial.merit_value <= trial.armijo_target
        for trial in result.diagnostics.accepted_trial_history
    )
    @test any(
        occursin("Armijo sufficient decrease", note) for note in result.diagnostics.notes
    )
end
