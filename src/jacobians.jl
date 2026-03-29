function finite_difference_jacobian(
    problem::StructureProblem,
    model::StellarModel;
    step::Real = problem.solver.finite_difference_step,
)
    base_vector = pack_state(model.structure)
    base_residual = assemble_structure_residual(problem, model)
    n = length(base_vector)
    jacobian = Matrix{Float64}(undef, length(base_residual), n)

    for j in 1:n
        perturbed = copy(base_vector)
        perturbed[j] += step
        trial_structure = unpack_state(model.structure, perturbed)
        trial_model = StellarModel(trial_structure, model.composition, model.evolution)
        trial_residual = assemble_structure_residual(problem, trial_model)
        jacobian[:, j] = (trial_residual .- base_residual) ./ step
    end

    return jacobian
end
