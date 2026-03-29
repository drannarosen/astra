@testset "block jacobian" begin
    problem = ASTRA.build_toy_problem(n_cells = 6)
    model = initialize_state(problem)

    jacobian = ASTRA.structure_jacobian(problem, model)
    fd_jacobian = ASTRA.finite_difference_jacobian(problem, model)

    @test size(jacobian) == size(fd_jacobian)
    @test all(isfinite, jacobian)
    @test isapprox(jacobian, fd_jacobian; rtol = 1.0e-3, atol = 1.0e-6)
end
