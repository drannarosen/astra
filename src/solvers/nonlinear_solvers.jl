function solve_nonlinear_system(problem::StructureProblem, initial_state::StellarState)
    state = initial_state
    residual = assemble_structure_residual(problem, state)

    for iteration in 0:problem.solver.max_newton_iterations
        if converged_residual(problem, residual)
            diagnostics = build_diagnostics(problem, state, residual, iteration, true)
            return SolveResult(state, diagnostics)
        end

        jacobian = finite_difference_jacobian(problem, state)
        update = solve_linear_system(jacobian, -residual)
        next_vector = pack_state(state) .+ problem.solver.damping .* update
        state = unpack_state(state, next_vector)
        residual = assemble_structure_residual(problem, state)
    end

    diagnostics = build_diagnostics(
        problem,
        state,
        residual,
        problem.solver.max_newton_iterations,
        false,
    )
    return SolveResult(state, diagnostics)
end
