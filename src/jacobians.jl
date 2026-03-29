function finite_difference_jacobian(
    problem::StructureProblem,
    state::StellarState;
    step::Real = problem.solver.finite_difference_step,
)
    base_vector = pack_state(state)
    base_residual = assemble_structure_residual(problem, state)
    n = length(base_vector)
    jacobian = Matrix{Float64}(undef, length(base_residual), n)

    for j in 1:n
        perturbed = copy(base_vector)
        perturbed[j] += step
        trial_state = unpack_state(state, perturbed)
        trial_residual = assemble_structure_residual(problem, trial_state)
        jacobian[:, j] = (trial_residual .- base_residual) ./ step
    end

    return jacobian
end
