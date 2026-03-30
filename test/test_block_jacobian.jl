@testset "block jacobian" begin
    problem = ASTRA.build_toy_problem(n_cells = 6)
    model = initialize_state(problem)

    jacobian = ASTRA.structure_jacobian(problem, model)
    fd_jacobian = ASTRA.finite_difference_jacobian(problem, model)

    @test size(jacobian) == size(fd_jacobian)
    @test all(isfinite, jacobian)
    @test all(isfinite, fd_jacobian)
    # The luminosity block will later include eps_grav and eps_nu through the
    # energy-source assembly helper, so keep the full block comparison explicit.
    @test isapprox(jacobian, fd_jacobian; rtol = 5.0e-4, atol = 1.0e-6)
end
