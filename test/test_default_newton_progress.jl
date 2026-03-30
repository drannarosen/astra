@testset "default newton progress" begin
    problem = ASTRA.build_toy_problem(n_cells = 12)
    guess = initialize_state(problem)
    initial_residual = ASTRA.residual_norm(ASTRA.assemble_structure_residual(problem, guess))

    result = solve_structure(problem; state = guess)

    @test result.diagnostics.accepted_step_count >= 2
    @test result.diagnostics.iterations >= 2
    @test length(result.diagnostics.residual_history) >= 3
    @test all(isfinite, result.diagnostics.residual_history)
    @test isfinite(result.diagnostics.residual_norm)
    @test all(diff(result.diagnostics.residual_history) .< 0.0)
    @test result.diagnostics.residual_norm <= 0.99 * initial_residual
    @test any(
        note -> occursin("accepted", lowercase(note)) ||
            occursin("rejected", lowercase(note)),
        result.diagnostics.notes,
    )
end
