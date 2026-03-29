@testset "solver boundary api" begin
    problem = ASTRA.build_toy_problem(n_cells = 8)
    guess = initialize_state(problem)

    result = ASTRA.solve_structure(problem; state = guess)

    @test result isa ASTRA.SolveResult
    @test result.state isa ASTRA.StellarModel
    @test result.state.composition === guess.composition
    @test result.state.evolution !== nothing
    @test any(note -> occursin("solve boundary", lowercase(note)), result.diagnostics.notes)
end
