@testset "center asymptotics and luminosity conditioning" begin
    problem = ASTRA.build_toy_problem(n_cells = 8)
    model = initialize_state(problem)

    center_radius_cm = ASTRA.center_radius_series_target_cm(problem, model)
    center_luminosity_erg_s = ASTRA.center_luminosity_series_target_erg_s(problem, model)

    structure = model.structure
    center_log_radius_face_cm = copy(structure.log_radius_face_cm)
    center_luminosity_face_erg_s = copy(structure.luminosity_face_erg_s)

    center_log_radius_face_cm[1] = log(center_radius_cm)
    center_luminosity_face_erg_s[1] = center_luminosity_erg_s

    center_model = ASTRA.StellarModel(
        ASTRA.StructureState(
            structure.grid,
            center_log_radius_face_cm,
            center_luminosity_face_erg_s,
            copy(structure.log_temperature_cell_k),
            copy(structure.log_density_cell_g_cm3),
        ),
        model.composition,
        model.evolution,
    )

    center_residual = ASTRA.center_boundary_residual(problem, center_model)
    @test abs(center_residual[1]) <= 1.0e-12 * center_radius_cm
    @test abs(center_residual[2]) <= 1.0e-12 * center_luminosity_erg_s

    packed = ASTRA.pack_state(structure)
    lum_index = problem.grid.n_cells + 2
    lum_step = ASTRA.jacobian_column_step(packed, lum_index, problem.solver.finite_difference_step)
    @test lum_step ≈ packed[lum_index] * problem.solver.finite_difference_step
    @test lum_step > 1.0e20

    scale = ASTRA.Solvers.state_scaling(problem, model)
    @test all(scale[1:(problem.grid.n_cells + 1)] .== 1.0)
    @test all(scale[(2 * problem.grid.n_cells + 3):end] .== 1.0)
    @test all(scale[(problem.grid.n_cells + 2):(2 * problem.grid.n_cells + 2)] .>=
              problem.parameters.luminosity_guess_erg_s)
end
