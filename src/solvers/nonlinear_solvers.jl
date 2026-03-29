function solve_nonlinear_system(problem::StructureProblem, initial_model::StellarModel)
    model = initial_model
    residual = assemble_structure_residual(problem, model)

    for iteration in 0:problem.solver.max_newton_iterations
        if converged_residual(problem, residual)
            diagnostics = build_diagnostics(problem, model, residual, iteration, true)
            return SolveResult(model, diagnostics)
        end

        jacobian = finite_difference_jacobian(problem, model)
        update = solve_linear_system(jacobian, -residual)
        next_vector = pack_state(model.structure) .+ problem.solver.damping .* update
        next_structure = unpack_state(model.structure, next_vector)
        model = StellarModel(next_structure, model.composition, model.evolution)
        residual = assemble_structure_residual(problem, model)
    end

    diagnostics = build_diagnostics(
        problem,
        model,
        residual,
        problem.solver.max_newton_iterations,
        false,
    )
    return SolveResult(model, diagnostics)
end
