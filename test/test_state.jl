@testset "state" begin
    parameters = StellarParameters(mass_g = ASTRA.SOLAR_MASS_G)
    composition = Composition(0.70, 0.28, 0.02)
    grid = build_grid(parameters, GridConfig(n_cells = 10))
    model = initialize_state(parameters, composition, grid)

    packed = ASTRA.pack_state(model.structure)
    restored = ASTRA.unpack_state(model.structure, packed)

    @test length(model.structure.log_radius_face_cm) == 11
    @test length(model.structure.log_temperature_cell_k) == 10
    @test length(model.composition.hydrogen_mass_fraction_cell) == 10
    @test length(packed) == 42
    @test restored.log_radius_face_cm == model.structure.log_radius_face_cm
    @test restored.log_density_cell_g_cm3 == model.structure.log_density_cell_g_cm3
end
