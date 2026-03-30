@testset "classical convergence basin" begin
    problem = ASTRA.build_toy_problem(n_cells = 12)
    result = solve_structure(problem)

    @test result.state isa ASTRA.StellarModel
    @test isfinite(result.diagnostics.residual_norm)
    @test result.diagnostics.residual_norm < 1.0e31
    @test any(
        note -> occursin("initial guess", lowercase(note)),
        result.diagnostics.notes,
    )
end
