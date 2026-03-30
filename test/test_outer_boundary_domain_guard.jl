@testset "outer boundary domain guard" begin
    problem = ASTRA.build_toy_problem(n_cells = 8)
    model = ASTRA.initialize_state(problem)
    update = zeros(length(ASTRA.pack_state(model.structure)))
    surface_luminosity_index = 2 * (problem.grid.n_cells + 1)
    update[surface_luminosity_index] = -10.0 * abs(model.structure.luminosity_face_erg_s[end])

    limited = ASTRA.Solvers.limit_outer_boundary_domain(problem, model, update)
    trial_vector = ASTRA.pack_state(model.structure) .+ limited.update
    trial_structure = ASTRA.unpack_state(model.structure, trial_vector)

    @test limited.factor < 1.0
    @test trial_structure.luminosity_face_erg_s[end] > 0.0
end
