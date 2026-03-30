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
    center_radius_cm = ASTRA.center_radius_series_target_cm(problem, model)
    center_luminosity_erg_s = ASTRA.center_luminosity_series_target_erg_s(problem, model)

    center_log_radius_face_cm[1] = log(center_radius_cm)
    center_luminosity_face_erg_s[1] = center_luminosity_erg_s

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
    @test abs(center_residual[1]) <= 1.0e-12 * center_radius_cm
    @test abs(center_residual[2]) <= 1.0e-12 * center_luminosity_erg_s

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
    surface_radius_cm = exp(surface_model.structure.log_radius_face_cm[end])
    surface_luminosity_erg_s = surface_model.structure.luminosity_face_erg_s[end]
    outer_temperature_k = exp(surface_model.structure.log_temperature_cell_k[end])
    outer_match_temperature_k = ASTRA.outer_match_temperature_k(problem, surface_model)
    outer_eos_state = ASTRA.cell_eos_state(problem, surface_model, problem.grid.n_cells)
    p_match_dyn_cm2 = ASTRA.outer_match_pressure_dyn_cm2(problem, surface_model)

    @test surface_residual[3] ≈ log(outer_temperature_k) - log(outer_match_temperature_k)
    @test surface_residual[4] ≈ outer_eos_state.pressure_dyn_cm2 - p_match_dyn_cm2
    @test outer_match_temperature_k > ASTRA.surface_effective_temperature_k(
        surface_radius_cm,
        surface_luminosity_erg_s,
    )
end
