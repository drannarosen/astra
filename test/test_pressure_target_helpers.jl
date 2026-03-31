using Test
using ASTRA

@testset "pressure target helpers" begin
    problem = ASTRA.build_toy_problem(n_cells = 12)
    model = ASTRA.initialize_state(problem)
    n = problem.grid.n_cells

    radius_surface_cm = exp(model.structure.log_radius_face_cm[end])
    opacity_outer_cm2_g = ASTRA.cell_opacity_state(problem, model, n).opacity_cm2_g
    g_surface_cgs = ASTRA.surface_gravity_cgs(problem.parameters.mass_g, radius_surface_cm)
    p_ph = ASTRA._photospheric_face_pressure_target_dyn_cm2(problem, model)
    p_bridge = ASTRA._bridge_pressure_target_dyn_cm2(problem, model)
    sigma_half =
        ASTRA.outer_half_cell_column_density_g_cm2(problem.grid.dm_cell_g[end], radius_surface_cm)

    @test p_ph ≈ ASTRA.eddington_photospheric_pressure_dyn_cm2(g_surface_cgs, opacity_outer_cm2_g)
    @test p_bridge ≈ p_ph + g_surface_cgs * sigma_half
    @test p_bridge > p_ph
end
