using Test
using ASTRA

@testset "outer transport pressure mode" begin
    base_problem = ASTRA.build_toy_problem(n_cells = 12)
    aligned_solver = ASTRA.SolverConfig(
        outer_transport_pressure_mode = :selected_pressure_target,
    )
    aligned_problem = ASTRA.StructureProblem(
        base_problem.formulation,
        base_problem.parameters,
        base_problem.composition,
        base_problem.grid,
        base_problem.microphysics,
        aligned_solver,
    )

    base_model = ASTRA.initialize_state(base_problem)
    aligned_model = ASTRA.initialize_state(aligned_problem)

    base_outer =
        ASTRA.transport_row_terms(base_problem, base_model, base_problem.grid.n_cells - 1)
    aligned_outer = ASTRA.transport_row_terms(
        aligned_problem,
        aligned_model,
        aligned_problem.grid.n_cells - 1,
    )

    @test base_problem.solver.outer_transport_pressure_mode == :photospheric_face
    @test aligned_problem.solver.outer_transport_pressure_mode == :selected_pressure_target
    @test base_outer.location == :outer
    @test aligned_outer.location == :outer
    @test aligned_outer.transport_pressure_target_dyn_cm2 ≈
          ASTRA._selected_pressure_target_dyn_cm2(aligned_problem, aligned_model)
end
