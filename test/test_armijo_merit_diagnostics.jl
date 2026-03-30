using LinearAlgebra: dot

@testset "armijo merit helpers" begin
    residual = Float64[3.0, -4.0]
    row_weights = Float64[2.0, 0.5]
    jacobian_times_step = Float64[-2.0, 1.0]
    damping = 0.25

    base_merit = ASTRA.Solvers.weighted_residual_merit(residual, row_weights)
    slope = ASTRA.Solvers.weighted_merit_slope(residual, jacobian_times_step, row_weights)
    predicted_merit = ASTRA.Solvers.linearized_weighted_residual_merit(
        residual,
        jacobian_times_step,
        row_weights;
        damping = damping,
    )
    predicted_decrease = ASTRA.Solvers.predicted_merit_decrease(
        residual,
        jacobian_times_step,
        row_weights;
        damping = damping,
    )
    actual_decrease = ASTRA.Solvers.actual_merit_decrease(base_merit, predicted_merit)
    ratio = ASTRA.Solvers.merit_decrease_ratio(predicted_decrease, actual_decrease)
    armijo_target = ASTRA.Solvers.armijo_target_merit(base_merit, damping, slope)

    weighted_residual = row_weights .* residual
    weighted_jstep = row_weights .* jacobian_times_step

    @test slope ≈ dot(weighted_residual, weighted_jstep) rtol = 1e-12
    @test predicted_merit ≈
          0.5 * sum(abs2, weighted_residual .+ damping .* weighted_jstep) rtol = 1e-12
    @test predicted_decrease ≈ base_merit - predicted_merit rtol = 1e-12
    @test actual_decrease ≈ predicted_decrease rtol = 1e-12
    @test ratio ≈ 1.0 rtol = 1e-12
    @test armijo_target ≈
          base_merit + ASTRA.Solvers.ARMIJO_SUFFICIENT_DECREASE * damping * slope rtol = 1e-12
end

@testset "merit decrease ratio handles nonpositive predicted decrease" begin
    @test isnan(ASTRA.Solvers.merit_decrease_ratio(0.0, 1.0))
    @test isnan(ASTRA.Solvers.merit_decrease_ratio(-1.0, 1.0))
end
