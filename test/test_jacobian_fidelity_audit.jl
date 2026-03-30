@testset "jacobian fidelity audit" begin
    problem = ASTRA.build_toy_problem(n_cells = 6)
    model = initialize_state(problem)

    audit = ASTRA.jacobian_fidelity_audit(problem, model)

    @test haskey(pairs(audit), :center)
    @test haskey(pairs(audit), :geometry)
    @test haskey(pairs(audit), :luminosity)
    @test haskey(pairs(audit), :hydrostatic)
    @test haskey(pairs(audit), :transport)

    for family in (:center, :geometry, :luminosity, :hydrostatic, :transport)
        report = getproperty(audit, family)
        @test report.row_count >= 1
        @test report.column_count >= 1
        @test isfinite(report.max_abs_error)
        @test isfinite(report.max_rel_error)
    end

    @test audit.center.max_rel_error <= 2.0e-8
    @test audit.geometry.max_rel_error <= 1.0e-5
    @test audit.luminosity.max_rel_error <= 5.0e-4
    @test audit.hydrostatic.max_rel_error <= 1.0e-6
    @test audit.transport.max_rel_error <= 1.0e-6
end
