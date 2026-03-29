@testset "local derivative validation" begin
    problem = ASTRA.build_toy_problem(n_cells = 6)
    model = initialize_state(problem)
    k = 2

    fd = ASTRA.finite_difference_temperature_gradient_sensitivity(problem, model, k)
    analytic = ASTRA.helper_temperature_gradient_sensitivity(problem, model, k)

    @test isfinite(fd)
    @test isfinite(analytic)
    @test isapprox(analytic, fd; rtol = 1.0e-4, atol = 1.0e-8)
end
