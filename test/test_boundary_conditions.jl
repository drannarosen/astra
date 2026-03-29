@testset "boundary conditions" begin
    problem = ASTRA.build_toy_problem(n_cells = 8)
    model = initialize_state(problem)

    center = ASTRA.center_boundary_residual(problem, model)
    surface = ASTRA.surface_boundary_residual(problem, model)

    @test length(center) == 2
    @test length(surface) == 4
    @test all(isfinite, center)
    @test all(isfinite, surface)

    center_log_radius_face_cm = copy(model.structure.log_radius_face_cm)
    center_luminosity_face_erg_s = copy(model.structure.luminosity_face_erg_s)
    center_log_temperature_cell_k = copy(model.structure.log_temperature_cell_k)
    center_log_density_cell_g_cm3 = copy(model.structure.log_density_cell_g_cm3)
    dm_1 = problem.grid.dm_cell_g[1]
    rho_1 = 100.0
    r_inner_cm = 1.0e8
    r_outer_cm = (r_inner_cm^3 + (3.0 * dm_1) / (4.0 * π * rho_1))^(1.0 / 3.0)

    center_log_radius_face_cm[1] = log(r_inner_cm)
    center_log_radius_face_cm[2] = log(r_outer_cm)
    center_luminosity_face_erg_s[1] = 0.0
    center_log_density_cell_g_cm3[1] = log(rho_1)

    center_model = ASTRA.StellarModel(
        ASTRA.StructureState(
            model.structure.grid,
            center_log_radius_face_cm,
            center_luminosity_face_erg_s,
            center_log_temperature_cell_k,
            center_log_density_cell_g_cm3,
        ),
        model.composition,
        model.evolution,
    )

    center_residual = ASTRA.center_boundary_residual(problem, center_model)
    @test abs(center_residual[1]) <= 1.0e-12 * (dm_1 / rho_1)
    @test center_residual[2] == 0.0

    surface_log_radius_face_cm = copy(model.structure.log_radius_face_cm)
    surface_luminosity_face_erg_s = copy(model.structure.luminosity_face_erg_s)
    surface_log_temperature_cell_k = copy(model.structure.log_temperature_cell_k)
    surface_log_density_cell_g_cm3 = copy(model.structure.log_density_cell_g_cm3)

    surface_log_radius_face_cm[end] = log(problem.parameters.radius_guess_cm)
    surface_luminosity_face_erg_s[end] = problem.parameters.luminosity_guess_erg_s
    surface_log_temperature_cell_k[end] = log(problem.parameters.surface_temperature_guess_k)
    surface_log_density_cell_g_cm3[end] = log(1.0e-7)

    surface_model = ASTRA.StellarModel(
        ASTRA.StructureState(
            model.structure.grid,
            surface_log_radius_face_cm,
            surface_luminosity_face_erg_s,
            surface_log_temperature_cell_k,
            surface_log_density_cell_g_cm3,
        ),
        model.composition,
        model.evolution,
    )

    surface_residual = ASTRA.surface_boundary_residual(problem, surface_model)
    @test surface_residual[1] ≈ 0.0 atol = 1.0e-4
    @test surface_residual[2] == 0.0
    @test surface_residual[3] ≈ 0.0 atol = 1.0e-9
    @test surface_residual[4] ≈ 0.0 atol = 1.0e-20
end
