using Random

function _capped_exit_progress_fixture()
    problem = ASTRA.build_toy_problem(n_cells = 6)
    solver = ASTRA.SolverConfig(max_newton_iterations = 1)
    capped_problem = ASTRA.StructureProblem(
        problem.formulation,
        problem.parameters,
        problem.composition,
        problem.grid,
        problem.microphysics,
        solver,
    )
    base_state = initialize_state(capped_problem)
    base_vector = ASTRA.pack_state(base_state.structure)
    Random.seed!(42)
    state = base_state

    for _ in 1:223
        perturbed_vector =
            base_vector .+ 1.0e-6 .* randn(length(base_vector)) .* abs.(base_vector)
        perturbed_structure = ASTRA.unpack_state(base_state.structure, perturbed_vector)
        state = ASTRA.StellarModel(
            perturbed_structure,
            base_state.composition,
            base_state.evolution,
        )
    end

    return capped_problem, state
end

@testset "solver progress diagnostics" begin
    problem = ASTRA.build_toy_problem(n_cells = 12)
    guess = initialize_state(problem)
    initial_residual = ASTRA.residual_norm(ASTRA.assemble_structure_residual(problem, guess))

    result = solve_structure(problem; state = guess)

    @test result.diagnostics.initial_residual_norm ≈ initial_residual
    @test !isempty(result.diagnostics.residual_history)
    @test first(result.diagnostics.residual_history) ≈ initial_residual
    @test last(result.diagnostics.residual_history) ≈ result.diagnostics.residual_norm
    @test result.diagnostics.accepted_step_count >= 0
    @test result.diagnostics.rejected_trial_count >= 0
    @test length(result.diagnostics.damping_history) == result.diagnostics.accepted_step_count
    @test all(0.0 < damping <= problem.solver.damping for damping in result.diagnostics.damping_history)

    if !result.diagnostics.converged && result.diagnostics.accepted_step_count == 0
        @test result.diagnostics.rejected_trial_count > 0
        @test any(
            note -> occursin("backtracking exhausted", lowercase(note)) ||
                occursin("no residual-reducing trial step", lowercase(note)),
            result.diagnostics.notes,
        )
    end

    capped_problem, capped_state = _capped_exit_progress_fixture()
    capped_initial_residual = ASTRA.residual_norm(
        ASTRA.assemble_structure_residual(capped_problem, capped_state),
    )
    capped_result = solve_structure(capped_problem; state = capped_state)

    @test !capped_result.diagnostics.converged
    @test capped_result.diagnostics.accepted_step_count ==
          capped_problem.solver.max_newton_iterations
    @test capped_result.diagnostics.iterations == capped_problem.solver.max_newton_iterations
    @test capped_result.diagnostics.iterations == capped_result.diagnostics.accepted_step_count
    @test length(capped_result.diagnostics.residual_history) ==
          capped_result.diagnostics.iterations + 1
    @test capped_result.diagnostics.initial_residual_norm ≈ capped_initial_residual
    @test first(capped_result.diagnostics.residual_history) ≈ capped_initial_residual
    @test last(capped_result.diagnostics.residual_history) ≈
          capped_result.diagnostics.residual_norm
end
