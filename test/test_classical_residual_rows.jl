@testset "classical residual rows" begin
    problem = ASTRA.build_toy_problem(n_cells = 6)
    model = initialize_state(problem)
    residual = ASTRA.assemble_structure_residual(problem, model)

    @test length(residual) == length(ASTRA.pack_state(model.structure))
    @test residual[1:2] == ASTRA.center_boundary_residual(problem, model)
    @test residual[(end - 3):end] == ASTRA.surface_boundary_residual(problem, model)

    block = ASTRA.interior_structure_block(problem, model, 1)
    @test residual[3:6] == block
end
