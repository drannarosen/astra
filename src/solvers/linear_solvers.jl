"""
    solve_linear_system(matrix, rhs)

Solve the current dense linearized Newton system. The linear-solver boundary is
kept explicit so ASTRA can swap Jacobian builders or outer linear algebra later
without changing the nonlinear orchestration contract.
"""
solve_linear_system(matrix::AbstractMatrix{<:Real}, rhs::AbstractVector{<:Real}) = matrix \ rhs
