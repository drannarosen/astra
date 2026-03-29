"""
    GridConfig(; n_cells = 64, inner_mass_fraction = 1e-8)

Configuration for ASTRA's mass grid construction.
"""
struct GridConfig
    n_cells::Int
    inner_mass_fraction::Float64

    function GridConfig(; n_cells::Int = 64, inner_mass_fraction::Real = 1.0e-8)
        n_cells > 1 || throw(ArgumentError("GridConfig requires at least two cells."))
        0.0 < inner_mass_fraction < 1.0 || throw(
            ArgumentError("inner_mass_fraction must lie between 0 and 1."),
        )
        return new(n_cells, Float64(inner_mass_fraction))
    end
end

"""
    SolverConfig(; max_newton_iterations = 8, damping = 1.0, tolerance = 1e-10, finite_difference_step = 1e-6)

Control parameters for ASTRA's bootstrap nonlinear solve.
"""
struct SolverConfig
    max_newton_iterations::Int
    damping::Float64
    tolerance::Float64
    finite_difference_step::Float64

    function SolverConfig(;
        max_newton_iterations::Int = 8,
        damping::Real = 1.0,
        tolerance::Real = 1.0e-10,
        finite_difference_step::Real = 1.0e-6,
    )
        max_newton_iterations > 0 || throw(
            ArgumentError("max_newton_iterations must be positive."),
        )
        0.0 < damping <= 1.0 || throw(ArgumentError("damping must lie in (0, 1]."))
        tolerance > 0.0 || throw(ArgumentError("tolerance must be positive."))
        finite_difference_step > 0.0 || throw(
            ArgumentError("finite_difference_step must be positive."),
        )
        return new(
            max_newton_iterations,
            Float64(damping),
            Float64(tolerance),
            Float64(finite_difference_step),
        )
    end
end
