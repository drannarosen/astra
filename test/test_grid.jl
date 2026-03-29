@testset "grid" begin
    parameters = StellarParameters(mass_g = ASTRA.SOLAR_MASS_G)
    config = GridConfig(n_cells = 12, inner_mass_fraction = 1.0e-8)
    grid = build_grid(parameters, config)

    @test length(grid.m_face_g) == 13
    @test length(grid.dm_cell_g) == 12
    @test all(diff(grid.m_face_g) .> 0.0)
    @test isapprox(sum(grid.dm_cell_g), parameters.mass_g - first(grid.m_face_g); rtol = 1e-10)
end
