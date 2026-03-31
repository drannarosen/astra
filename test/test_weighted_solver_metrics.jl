@testset "weighted solver metrics" begin
    problem = ASTRA.build_toy_problem(n_cells = 8)
    model = initialize_state(problem)
    residual = ASTRA.assemble_structure_residual(problem, model)

    row_weights = ASTRA.Solvers.residual_row_weights(problem, model)
    correction_weights = ASTRA.Solvers.correction_weights(problem, model)

    @test length(row_weights) == length(residual)
    @test length(correction_weights) == length(ASTRA.pack_state(model.structure))
    @test all(isfinite, row_weights)
    @test all(>(0.0), row_weights)
    @test all(isfinite, correction_weights)
    @test all(>(0.0), correction_weights)

    center_radius_weight = inv(ASTRA.center_radius_series_target_cm(problem, model))
    center_luminosity_weight = inv(ASTRA.center_luminosity_series_target_erg_s(problem, model))
    @test row_weights[first(ASTRA.structure_center_row_range())] ≈ center_radius_weight
    @test row_weights[last(ASTRA.structure_center_row_range())] ≈ center_luminosity_weight

    k = 1
    row_range = ASTRA.interior_structure_row_range(k)
    state = model.structure
    r_left_cm = exp(state.log_radius_face_cm[k])
    r_right_cm = exp(state.log_radius_face_cm[k + 1])
    density_g_cm3 = exp(state.log_density_cell_g_cm3[k])
    pressure_k_dyn_cm2 = ASTRA.cell_eos_state(problem, model, k).pressure_dyn_cm2
    pressure_kp1_dyn_cm2 = ASTRA.cell_eos_state(problem, model, k + 1).pressure_dyn_cm2
    energy_rate_erg_g_s = ASTRA.energy_source_terms(problem, model, k).eps_total_erg_g_s
    dm_g = problem.grid.dm_cell_g[k]
    enclosed_mass_g = problem.grid.m_face_g[k + 1]
    gravity_term_dyn_cm2 =
        ASTRA.GRAVITATIONAL_CONSTANT_CGS * enclosed_mass_g * dm_g /
        (4.0 * π * r_right_cm^4)
    geometry_scale = max(ASTRA.shell_volume_cm3(r_left_cm, r_right_cm), dm_g / density_g_cm3)
    hydrostatic_scale = max(max(abs(pressure_k_dyn_cm2), abs(pressure_kp1_dyn_cm2)), gravity_term_dyn_cm2)
    luminosity_scale = max(
        max(abs(state.luminosity_face_erg_s[k]), abs(state.luminosity_face_erg_s[k + 1])),
        abs(dm_g * energy_rate_erg_g_s),
    )

    @test row_weights[first(row_range)] ≈ inv(geometry_scale)
    @test row_weights[first(row_range) + 1] ≈ inv(hydrostatic_scale)
    @test row_weights[first(row_range) + 2] ≈ inv(luminosity_scale)
    @test row_weights[first(row_range) + 3] ≈ 1.0

    surface_rows = ASTRA.structure_surface_row_range(problem.grid.n_cells)
    @test row_weights[surface_rows[4]] == 1.0

    weighted_norm = ASTRA.Solvers.weighted_residual_norm(problem, model, residual)
    @test isfinite(weighted_norm)
    @test weighted_norm >= 0.0
end

@testset "luminosity correction weights stay finite near zero" begin
    problem = ASTRA.build_toy_problem(n_cells = 8)
    model = initialize_state(problem)
    structure = model.structure
    zero_luminosity_model = ASTRA.StellarModel(
        ASTRA.StructureState(
            structure.grid,
            copy(structure.log_radius_face_cm),
            zeros(length(structure.luminosity_face_erg_s)),
            copy(structure.log_temperature_cell_k),
            copy(structure.log_density_cell_g_cm3),
        ),
        model.composition,
        model.evolution,
    )

    correction_weights = ASTRA.Solvers.correction_weights(problem, zero_luminosity_model)
    lum_range = (problem.grid.n_cells + 2):(2 * problem.grid.n_cells + 2)
    expected_floor = inv(problem.parameters.luminosity_guess_erg_s)

    @test all(isfinite, correction_weights[lum_range])
    @test all(>(0.0), correction_weights[lum_range])
    @test all(correction_weights[lum_range] .<= expected_floor)
    @test correction_weights[first(lum_range)] ≈ expected_floor
end

@testset "weighted correction limiting shrinks oversized trial steps" begin
    problem = ASTRA.build_toy_problem(n_cells = 8)
    model = initialize_state(problem)
    update = zeros(length(ASTRA.pack_state(model.structure)))
    lum_index = problem.grid.n_cells + 2
    update[lum_index] = 10.0 * problem.parameters.luminosity_guess_erg_s

    limited = ASTRA.Solvers.limit_weighted_correction(problem, model, update)

    @test limited.factor < 1.0
    @test limited.weighted_max_correction <= 1.0 + 1.0e-12
    @test limited.weighted_correction_norm <= 1.0 + 1.0e-12
    @test limited.update ≈ limited.factor .* update
end
