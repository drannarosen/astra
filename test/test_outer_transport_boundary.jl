@testset "outer transport boundary" begin
    problem = ASTRA.build_toy_problem(n_cells = 8)
    model = initialize_state(problem)
    residual = ASTRA.assemble_structure_residual(problem, model)

    n = problem.grid.n_cells
    transport_row = first(ASTRA.interior_structure_row_range(n - 1)) + 3
    outer_cell_temperature_k = exp(model.structure.log_temperature_cell_k[n - 1])
    outer_cell_pressure_dyn_cm2 = ASTRA.cell_eos_state(problem, model, n - 1).pressure_dyn_cm2
    nabla_outer = ASTRA.radiative_temperature_gradient(problem, model, n - 1)
    outer_match_temperature_k = ASTRA.outer_match_temperature_k(problem, model)
    outer_match_pressure_dyn_cm2 = ASTRA.outer_match_pressure_dyn_cm2(problem, model)

    expected = log(outer_match_temperature_k) - log(outer_cell_temperature_k) +
        nabla_outer * (
            log(outer_match_pressure_dyn_cm2) - log(outer_cell_pressure_dyn_cm2)
        )

    @test residual[transport_row] ≈ expected
end
