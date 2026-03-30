function converged_residual(
    problem::StructureProblem,
    model::StellarModel,
    residual::AbstractVector{<:Real},
)
    return weighted_residual_norm(problem, model, residual) <= problem.solver.tolerance
end
