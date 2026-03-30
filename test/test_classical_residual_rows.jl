@testset "classical residual rows" begin
    problem = ASTRA.build_toy_problem(n_cells = 6)
    model = initialize_state(problem)
    residual = ASTRA.assemble_structure_residual(problem, model)

    @test length(residual) == length(ASTRA.pack_state(model.structure))
    @test residual[1:2] == ASTRA.center_boundary_residual(problem, model)
    @test residual[(end - 3):end] == ASTRA.surface_boundary_residual(problem, model)

    block = ASTRA.interior_structure_block(problem, model, 1)
    @test residual[3:6] == block

    sources = ASTRA.energy_source_terms(problem, model, 1)
    dm_g = problem.grid.dm_cell_g[1]
    @test block[3] ≈
        model.structure.luminosity_face_erg_s[2] -
        model.structure.luminosity_face_erg_s[1] -
        dm_g * sources.eps_total_erg_g_s
end
