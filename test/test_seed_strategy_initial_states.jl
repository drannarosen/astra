@testset "seed strategy initial states" begin
    problem = ASTRA.build_toy_problem(n_cells = 12)

    default_state = ASTRA.initialize_state(problem)
    bootstrap_state = ASTRA._bootstrap_default_initial_state(problem)
    pms_like_state = ASTRA._convective_pms_like_initial_state(problem)

    @test ASTRA.pack_state(default_state.structure) == ASTRA.pack_state(bootstrap_state.structure)
    @test default_state.composition == bootstrap_state.composition
    @test default_state.evolution == bootstrap_state.evolution

    @test length(pms_like_state.structure.log_radius_face_cm) == problem.grid.n_cells + 1
    @test length(pms_like_state.structure.log_temperature_cell_k) == problem.grid.n_cells
    @test length(pms_like_state.structure.log_density_cell_g_cm3) == problem.grid.n_cells
    @test all(isfinite, ASTRA.pack_state(pms_like_state.structure))
    @test all(>(0.0), exp.(pms_like_state.structure.log_radius_face_cm))
    @test all(>(0.0), exp.(pms_like_state.structure.log_temperature_cell_k))
    @test all(>(0.0), exp.(pms_like_state.structure.log_density_cell_g_cm3))
    @test pms_like_state.structure.log_radius_face_cm[end] ≈ log(problem.parameters.radius_guess_cm)
    @test exp(pms_like_state.structure.log_temperature_cell_k[end]) ≈
          problem.parameters.surface_temperature_guess_k rtol = 1.0e-12
    @test exp(pms_like_state.structure.log_temperature_cell_k[1]) <
          exp(default_state.structure.log_temperature_cell_k[1])
    @test pms_like_state.structure.luminosity_face_erg_s[end] >
          problem.parameters.luminosity_guess_erg_s
end
