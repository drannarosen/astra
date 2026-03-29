@testset "residual scaffold" begin
    problem = ASTRA.build_toy_problem(n_cells = 8)
    model = initialize_state(problem)
    packed = ASTRA.pack_state(model.structure)
    residual = ASTRA.assemble_structure_residual(problem, model)
    center = ASTRA.center_boundary_residual(problem, model)
    surface = ASTRA.surface_boundary_residual(problem, model)

    @test length(model.composition.hydrogen_mass_fraction_cell) == model.structure.grid.n_cells
    @test length(packed) == 4 * model.structure.grid.n_cells + 2
    @test length(residual) == length(packed)
    @test all(isfinite, residual)
    @test residual[1:2] == center
    @test residual[(end - 3):end] == surface

    trial_structure = ASTRA.StructureState(
        model.structure.grid,
        copy(model.structure.log_radius_face_cm),
        copy(model.structure.luminosity_face_erg_s),
        copy(model.structure.log_temperature_cell_k),
        copy(model.structure.log_density_cell_g_cm3),
    )
    trial_structure.log_radius_face_cm[2] += 1.0e-3
    trial_structure.luminosity_face_erg_s[2] += 1.0e20
    trial_structure.log_temperature_cell_k[1] += 3.0e-3
    trial_structure.log_density_cell_g_cm3[1] += 4.0e-3
    trial_model = ASTRA.StellarModel(trial_structure, model.composition, model.evolution)
    trial_residual = ASTRA.assemble_structure_residual(problem, trial_model)

    @test trial_model.composition === model.composition
    @test trial_model.evolution === model.evolution
    @test length(trial_model.composition.hydrogen_mass_fraction_cell) ==
          length(model.composition.hydrogen_mass_fraction_cell)
    @test trial_residual[3:6] != residual[3:6]
end
