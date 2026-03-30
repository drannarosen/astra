@testset "default newton progress" begin
    problem = ASTRA.build_toy_problem(n_cells = 12)
    guess = initialize_state(problem)
    initial_residual = ASTRA.residual_norm(ASTRA.assemble_structure_residual(problem, guess))
    initial_weighted_residual = ASTRA.Solvers.weighted_residual_norm(
        problem,
        guess,
        ASTRA.assemble_structure_residual(problem, guess),
    )

    result = solve_structure(problem; state = guess)

    @test result.diagnostics.accepted_step_count >= 1
    @test result.diagnostics.iterations >= 1
    @test length(result.diagnostics.residual_history) >= 2
    @test length(result.diagnostics.weighted_residual_history) >= 2
    @test all(isfinite, result.diagnostics.residual_history)
    @test all(isfinite, result.diagnostics.weighted_residual_history)
    @test isfinite(result.diagnostics.residual_norm)
    @test isfinite(result.diagnostics.weighted_residual_norm)
    @test all(diff(result.diagnostics.weighted_residual_history) .< 0.0)
    @test result.diagnostics.weighted_residual_norm <= 0.999 * initial_weighted_residual
    @test result.diagnostics.residual_norm <= initial_residual
    @test any(
        note -> occursin("accepted", lowercase(note)) ||
            occursin("backtracking", lowercase(note)) ||
            occursin("weighted", lowercase(note)),
        result.diagnostics.notes,
    )
end
