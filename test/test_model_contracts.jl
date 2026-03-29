@testset "model contracts" begin
    problem = ASTRA.build_toy_problem(n_cells = 6)
    model = initialize_state(problem)

    @test model isa ASTRA.StellarModel
    @test model.structure isa ASTRA.StructureState
    @test model.composition isa ASTRA.CompositionState
    @test model.evolution isa ASTRA.EvolutionState
    @test length(model.structure.log_radius_face_cm) == 7
    @test length(model.composition.hydrogen_mass_fraction_cell) == 6
end
