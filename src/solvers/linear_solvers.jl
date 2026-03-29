"""
    state_scaling(problem, model)

Return a column-scaling vector for the current Newton solve. ASTRA keeps
solve-owned luminosity in cgs `erg/s`, so this is numerical conditioning, not a
change in physical ownership.
"""
function state_scaling(problem::StructureProblem, model::StellarModel)
    n = problem.grid.n_cells
    luminosity_scale = max.(
        abs.(model.structure.luminosity_face_erg_s),
        max(problem.parameters.luminosity_guess_erg_s, SOLAR_LUMINOSITY_ERG_S),
    )
    return vcat(ones(Float64, n + 1), luminosity_scale, ones(Float64, 2 * n))
end

_column_scaling_matrix(column_scale::AbstractVector{<:Real}) = Diagonal(Float64.(column_scale))

"""
    solve_linear_system(matrix, rhs; column_scale = nothing)

Solve the current dense linearized Newton system. The linear-solver boundary is
kept explicit so ASTRA can swap Jacobian builders or outer linear algebra later
without changing the nonlinear orchestration contract.
"""
function solve_linear_system(
    matrix::AbstractMatrix{<:Real},
    rhs::AbstractVector{<:Real};
    column_scale::Union{Nothing,AbstractVector{<:Real}} = nothing,
)
    if isnothing(column_scale)
        return matrix \ rhs
    end

    scaling = _column_scaling_matrix(column_scale)
    scaled_update = (matrix * scaling) \ rhs
    return scaling * scaled_update
end

function solve_regularized_linear_system(
    matrix::AbstractMatrix{<:Real},
    residual::AbstractVector{<:Real},
    regularization::Real;
    column_scale::Union{Nothing,AbstractVector{<:Real}} = nothing,
)
    if isnothing(column_scale)
        normal_matrix = matrix' * matrix + Float64(regularization) * I
        return normal_matrix \ (-(matrix' * residual))
    end

    scaling = _column_scaling_matrix(column_scale)
    scaled_matrix = matrix * scaling
    normal_matrix = scaled_matrix' * scaled_matrix + Float64(regularization) * I
    scaled_update = normal_matrix \ (-(scaled_matrix' * residual))
    return scaling * scaled_update
end
