function converged_residual(problem::StructureProblem, residual::AbstractVector{<:Real})
    return residual_norm(residual) <= problem.solver.tolerance
end
