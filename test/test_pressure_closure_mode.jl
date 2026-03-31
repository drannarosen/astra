using Test
using ASTRA

@testset "pressure closure mode" begin
    bridge_problem = ASTRA.build_toy_problem(n_cells = 12)
    photosphere_solver = ASTRA.SolverConfig(pressure_closure_mode = :photosphere_control)
    photosphere_problem = ASTRA.StructureProblem(
        bridge_problem.formulation,
        bridge_problem.parameters,
        bridge_problem.composition,
        bridge_problem.grid,
        bridge_problem.microphysics,
        photosphere_solver,
    )

    bridge_model = ASTRA.initialize_state(bridge_problem)
    photosphere_model = ASTRA.initialize_state(photosphere_problem)

    bridge_residual = ASTRA.surface_boundary_residual(bridge_problem, bridge_model)
    photosphere_residual = ASTRA.surface_boundary_residual(photosphere_problem, photosphere_model)

    @test bridge_problem.solver.pressure_closure_mode == :bridge
    @test photosphere_problem.solver.pressure_closure_mode == :photosphere_control
    @test bridge_residual[4] ≈ ASTRA.surface_pressure_log_mismatch(
        ASTRA.cell_eos_state(bridge_problem, bridge_model, bridge_problem.grid.n_cells).pressure_dyn_cm2,
        ASTRA._bridge_pressure_target_dyn_cm2(bridge_problem, bridge_model),
    )
    @test photosphere_residual[4] ≈ ASTRA.surface_pressure_log_mismatch(
        ASTRA.cell_eos_state(
            photosphere_problem,
            photosphere_model,
            photosphere_problem.grid.n_cells,
        ).pressure_dyn_cm2,
        ASTRA._photospheric_face_pressure_target_dyn_cm2(
            photosphere_problem,
            photosphere_model,
        ),
    )
end
