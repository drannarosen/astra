@testset "outer transport boundary" begin
    problem = ASTRA.build_toy_problem(n_cells = 8)
    model = initialize_state(problem)
    residual = ASTRA.assemble_structure_residual(problem, model)

    n = problem.grid.n_cells
    transport_row = first(ASTRA.interior_structure_row_range(n - 1)) + 3
    surface_radius_cm = exp(model.structure.log_radius_face_cm[end])
    surface_luminosity_erg_s = model.structure.luminosity_face_erg_s[end]
    teff_k = ASTRA.surface_effective_temperature_k(surface_radius_cm, surface_luminosity_erg_s)
    g_surface_cgs = ASTRA.surface_gravity_cgs(problem.parameters.mass_g, surface_radius_cm)
    opacity_surface_state = ASTRA.cell_opacity_state(problem, model, n)
    p_ph_dyn_cm2 = ASTRA.eddington_photospheric_pressure_dyn_cm2(
        g_surface_cgs,
        opacity_surface_state.opacity_cm2_g,
    )
    outer_cell_temperature_k = exp(model.structure.log_temperature_cell_k[n - 1])
    outer_cell_pressure_dyn_cm2 = ASTRA.cell_eos_state(problem, model, n - 1).pressure_dyn_cm2
    nabla_outer = ASTRA.radiative_temperature_gradient(problem, model, n - 1)

    expected = log(teff_k) - log(outer_cell_temperature_k) +
        nabla_outer * (log(p_ph_dyn_cm2) - log(outer_cell_pressure_dyn_cm2))

    @test residual[transport_row] ≈ expected
end
