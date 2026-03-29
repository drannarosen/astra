@testset "solve contract" begin
    problem = ASTRA.build_toy_problem(n_cells = 8)
    result = solve_structure(problem)

    @test result.state isa ASTRA.StellarModel
    @test result.state.structure isa ASTRA.StructureState
    @test result.diagnostics.converged
    @test iszero(result.diagnostics.residual_norm)
end
