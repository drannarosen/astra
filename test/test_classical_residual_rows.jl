@testset "classical residual rows" begin
    problem = ASTRA.build_toy_problem(n_cells = 6)
    base_model = initialize_state(problem)
    model = ASTRA.with_previous_thermodynamic_state(
        base_model;
        previous_log_temperature_cell_k = base_model.structure.log_temperature_cell_k .- log(1.05),
        previous_log_density_cell_g_cm3 = base_model.structure.log_density_cell_g_cm3 .+ log(1.03),
        timestep_s = 1.0e11,
        previous_timestep_s = 0.9e11,
        accepted_steps = 1,
    )
    residual = ASTRA.assemble_structure_residual(problem, model)

    @test length(residual) == length(ASTRA.pack_state(model.structure))
    @test residual[1:2] == ASTRA.center_boundary_residual(problem, model)
    @test residual[(end - 3):end] == ASTRA.surface_boundary_residual(problem, model)

    block = ASTRA.interior_structure_block(problem, model, 1)
    @test residual[3:6] == block

    sources = ASTRA.energy_source_terms(problem, model, 1)
    dm_g = problem.grid.dm_cell_g[1]
    @test abs(sources.eps_grav_erg_g_s) > 0.0
    @test block[3] ≈
        model.structure.luminosity_face_erg_s[2] -
        model.structure.luminosity_face_erg_s[1] -
        dm_g * sources.eps_total_erg_g_s atol = 1.0e-6 rtol = 1.0e-10
end
