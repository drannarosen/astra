using Test
using ASTRA

@testset "outer atmosphere match point" begin
    problem = ASTRA.build_toy_problem(n_cells = 12)
    model = ASTRA.initialize_state(problem)
    n = problem.grid.n_cells

    radius_surface_cm = exp(model.structure.log_radius_face_cm[end])
    luminosity_surface_erg_s = model.structure.luminosity_face_erg_s[end]
    teff_k = ASTRA.surface_effective_temperature_k(radius_surface_cm, luminosity_surface_erg_s)
    opacity_outer = ASTRA.cell_opacity_state(problem, model, n).opacity_cm2_g
    g_surface = ASTRA.surface_gravity_cgs(problem.parameters.mass_g, radius_surface_cm)

    tau_match = ASTRA.outer_match_optical_depth(problem, model)
    t_match = ASTRA.outer_match_temperature_k(problem, model)
    p_match = ASTRA.outer_match_pressure_dyn_cm2(problem, model)
    p_ph = ASTRA.eddington_photospheric_pressure_dyn_cm2(g_surface, opacity_outer)

    @test tau_match > 2.0 / 3.0
    @test t_match > teff_k
    @test p_match > p_ph
end
