@testset "solver progress diagnostics" begin
    problem = ASTRA.build_toy_problem(n_cells = 12)
    guess = initialize_state(problem)
    initial_residual = ASTRA.residual_norm(ASTRA.assemble_structure_residual(problem, guess))

    result = solve_structure(problem; state = guess)

    @test result.diagnostics.initial_residual_norm ≈ initial_residual
    @test !isempty(result.diagnostics.residual_history)
    @test first(result.diagnostics.residual_history) ≈ initial_residual
    @test last(result.diagnostics.residual_history) ≈ result.diagnostics.residual_norm
    @test result.diagnostics.accepted_step_count >= 0
    @test result.diagnostics.rejected_trial_count >= 0
    @test length(result.diagnostics.damping_history) == result.diagnostics.accepted_step_count
end
