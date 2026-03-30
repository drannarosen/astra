@testset "outer transport boundary" begin
    problem = ASTRA.build_toy_problem(n_cells = 8)
    model = initialize_state(problem)
    residual = ASTRA.assemble_structure_residual(problem, model)

    n = problem.grid.n_cells
    transport_row = first(ASTRA.interior_structure_row_range(n - 1)) + 3
    outer = ASTRA.transport_row_terms(problem, model, n - 1)
    expected = outer.residual

    @test residual[transport_row] ≈ expected
end
