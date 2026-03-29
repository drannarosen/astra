@testset "solve contract" begin
    problem = ASTRA.build_toy_problem(n_cells = 8)
    result = solve_structure(problem)

    @test result.state isa ASTRA.StellarModel
    @test result.state.structure isa ASTRA.StructureState
    @test all(isfinite, ASTRA.pack_state(result.state.structure))
    @test isfinite(result.diagnostics.residual_norm)
    @test any(note -> occursin("classical structure equations", note), result.diagnostics.notes)
    @test any(note -> occursin("provisional", note), result.diagnostics.notes)
end
