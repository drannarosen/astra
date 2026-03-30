@testset "outer transport boundary" begin
    problem = ASTRA.build_toy_problem(n_cells = 8)
    model = initialize_state(problem)
    residual = ASTRA.assemble_structure_residual(problem, model)

    n = problem.grid.n_cells
    transport_row = first(ASTRA.interior_structure_row_range(n - 1)) + 3
    outer_cell_temperature_k = exp(model.structure.log_temperature_cell_k[n - 1])
    outer_cell_pressure_dyn_cm2 = ASTRA.cell_eos_state(problem, model, n - 1).pressure_dyn_cm2
    nabla_outer = ASTRA.radiative_temperature_gradient(problem, model, n - 1)
    radius_surface_cm = exp(model.structure.log_radius_face_cm[end])
    luminosity_surface_erg_s = model.structure.luminosity_face_erg_s[end]
    face_temperature_k = ASTRA.surface_effective_temperature_k(
        radius_surface_cm,
        luminosity_surface_erg_s,
    )
    surface_gravity_cgs_value = ASTRA.surface_gravity_cgs(problem.parameters.mass_g, radius_surface_cm)
    opacity_outer_cm2_g = ASTRA.cell_opacity_state(problem, model, n).opacity_cm2_g
    face_pressure_dyn_cm2 =
        ASTRA.eddington_photospheric_pressure_dyn_cm2(surface_gravity_cgs_value, opacity_outer_cm2_g)

    expected = log(face_temperature_k) - log(outer_cell_temperature_k) +
        nabla_outer * (
            log(face_pressure_dyn_cm2) - log(outer_cell_pressure_dyn_cm2)
        )

    @test residual[transport_row] ≈ expected
end
