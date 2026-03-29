@testset "boundary conditions" begin
    problem = ASTRA.build_toy_problem(n_cells = 8)
    state = initialize_state(problem)

    center = ASTRA.center_boundary_residual(problem, state)
    surface = ASTRA.surface_boundary_residual(problem, state)

    @test length(center) == 2
    @test length(surface) == 4
    @test all(isfinite, center)
    @test all(isfinite, surface)
end
