@testset "types" begin
    composition = Composition(0.70, 0.28, 0.02)
    parameters = StellarParameters(mass_g = ASTRA.SOLAR_MASS_G)
    grid_config = GridConfig(n_cells = 16)
    solver = SolverConfig()
    grid = build_grid(parameters, grid_config)
    structure = StructureState(
        grid,
        fill(log(1.0), grid.n_cells + 1),
        fill(1.0, grid.n_cells + 1),
        fill(log(1.0), grid.n_cells),
        fill(log(1.0), grid.n_cells),
    )
    composition_state = CompositionState(
        fill(composition.X, grid.n_cells),
        fill(composition.Y, grid.n_cells),
        fill(composition.Z, grid.n_cells),
    )
    evolution = EvolutionState(0.0, 1.0, 1.0, 0, 0)
    model = StellarModel(structure, composition_state, evolution)

    @test isapprox(composition.X + composition.Y + composition.Z, 1.0; atol = 1e-12)
    @test parameters.mass_g == ASTRA.SOLAR_MASS_G
    @test grid_config.n_cells == 16
    @test solver.max_newton_iterations > 0
    @test structure.grid === grid
    @test length(structure.log_radius_face_cm) == grid.n_cells + 1
    @test length(composition_state.hydrogen_mass_fraction_cell) == grid.n_cells
    @test evolution.previous_timestep_s == 1.0
    @test model.structure === structure
    @test model.composition === composition_state
    @test model.evolution === evolution
    @test_throws ArgumentError Composition(0.7, 0.4, 0.0)
end
