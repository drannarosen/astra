@testset "default newton progress" begin
    problem = ASTRA.build_toy_problem(n_cells = 12)
    guess = initialize_state(problem)
    initial_residual = ASTRA.residual_norm(ASTRA.assemble_structure_residual(problem, guess))

    result = solve_structure(problem; state = guess)

    @test result.diagnostics.accepted_step_count >= 1
    @test result.diagnostics.iterations >= 1
    @test result.diagnostics.residual_norm < initial_residual
    @test issorted(result.diagnostics.residual_history; rev = true)
    @test any(
        note -> occursin("accepted", lowercase(note)) ||
            occursin("rejected", lowercase(note)),
        result.diagnostics.notes,
    )
end
