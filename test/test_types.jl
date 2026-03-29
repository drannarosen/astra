@testset "types" begin
    composition = Composition(0.70, 0.28, 0.02)
    parameters = StellarParameters(mass_g = ASTRA.SOLAR_MASS_G)
    grid_config = GridConfig(n_cells = 16)
    solver = SolverConfig()

    @test isapprox(composition.X + composition.Y + composition.Z, 1.0; atol = 1e-12)
    @test parameters.mass_g == ASTRA.SOLAR_MASS_G
    @test grid_config.n_cells == 16
    @test solver.max_newton_iterations > 0
    @test_throws ArgumentError Composition(0.7, 0.4, 0.0)
end
