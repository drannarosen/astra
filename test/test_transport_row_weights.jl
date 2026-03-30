@testset "transport row weights" begin
    problem = ASTRA.build_toy_problem(n_cells = 8)
    model = ASTRA.initialize_state(problem)
    weights = ASTRA.Solvers.residual_row_weights(problem, model)
    n = problem.grid.n_cells

    interior_row = first(ASTRA.interior_structure_row_range(1)) + 3
    pressure_1 = ASTRA.cell_eos_state(problem, model, 1).pressure_dyn_cm2
    pressure_2 = ASTRA.cell_eos_state(problem, model, 2).pressure_dyn_cm2
    delta_log_temperature = model.structure.log_temperature_cell_k[2] -
                            model.structure.log_temperature_cell_k[1]
    delta_log_pressure = log(ASTRA.clip_positive(pressure_2)) - log(ASTRA.clip_positive(pressure_1))
    interior_gradient_term =
        ASTRA.radiative_temperature_gradient(problem, model, 1) * delta_log_pressure
    expected_interior_weight = 1.0 / max(
        abs(delta_log_temperature),
        abs(interior_gradient_term),
        1.0,
    )

    outer_k = n - 1
    outer_row = first(ASTRA.interior_structure_row_range(outer_k)) + 3
    radius_surface_cm = exp(model.structure.log_radius_face_cm[end])
    luminosity_surface_erg_s = model.structure.luminosity_face_erg_s[end]
    face_temperature_k = ASTRA.surface_effective_temperature_k(
        radius_surface_cm,
        luminosity_surface_erg_s,
    )
    outer_cell_pressure = ASTRA.cell_eos_state(problem, model, outer_k).pressure_dyn_cm2
    surface_gravity_cgs_value = ASTRA.surface_gravity_cgs(problem.parameters.mass_g, radius_surface_cm)
    opacity_outer_cm2_g = ASTRA.cell_opacity_state(problem, model, n).opacity_cm2_g
    face_pressure = ASTRA.eddington_photospheric_pressure_dyn_cm2(
        surface_gravity_cgs_value,
        opacity_outer_cm2_g,
    )
    delta_outer_log_temperature =
        ASTRA.positive_log(face_temperature_k) - model.structure.log_temperature_cell_k[outer_k]
    delta_outer_log_pressure =
        log(ASTRA.clip_positive(face_pressure)) - log(ASTRA.clip_positive(outer_cell_pressure))
    outer_gradient_term =
        ASTRA.radiative_temperature_gradient(problem, model, outer_k) * delta_outer_log_pressure
    expected_outer_weight = 1.0 / max(
        abs(delta_outer_log_temperature),
        abs(outer_gradient_term),
        1.0,
    )

    @test weights[interior_row] ≈ expected_interior_weight
    @test weights[outer_row] ≈ expected_outer_weight
end
