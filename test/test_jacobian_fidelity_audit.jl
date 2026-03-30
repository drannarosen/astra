@testset "jacobian fidelity audit" begin
    problem = ASTRA.build_toy_problem(n_cells = 6)
    base_model = initialize_state(problem)
    model = ASTRA.with_previous_thermodynamic_state(
        base_model;
        previous_log_temperature_cell_k = base_model.structure.log_temperature_cell_k .- log(1.05),
        previous_log_density_cell_g_cm3 = base_model.structure.log_density_cell_g_cm3 .+ log(1.03),
        timestep_s = 1.0e11,
        previous_timestep_s = 0.9e11,
        accepted_steps = 1,
    )

    audit = ASTRA.jacobian_fidelity_audit(problem, model; step = 1.0e-5)
    jacobian = ASTRA.structure_jacobian(problem, model)
    dm_g = problem.grid.dm_cell_g[1]
    n = problem.grid.n_cells
    row = first(ASTRA.interior_structure_row_range(1)) + 2
    log_temperature_column = 2 * (n + 1) + 1
    log_density_column = 2 * (n + 1) + n + 1
    step = 1.0e-6

    function perturb_structure(model, column, delta)
        values = ASTRA.pack_state(model.structure)
        values[column] += delta
        structure = ASTRA.unpack_state(model.structure, values)
        return ASTRA.StellarModel(structure, model.composition, model.evolution)
    end

    eps_total(model, k) = ASTRA.energy_source_terms(problem, model, k).eps_total_erg_g_s
    temperature_plus = perturb_structure(model, log_temperature_column, step)
    temperature_minus = perturb_structure(model, log_temperature_column, -step)
    density_plus = perturb_structure(model, log_density_column, step)
    density_minus = perturb_structure(model, log_density_column, -step)
    dε_total_dlnT =
        (eps_total(temperature_plus, 1) - eps_total(temperature_minus, 1)) / (2.0 * step)
    dε_total_dlnρ =
        (eps_total(density_plus, 1) - eps_total(density_minus, 1)) / (2.0 * step)

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

    @test audit.center.max_rel_error <= 2.0e-7
    @test audit.geometry.max_rel_error <= 1.0e-5
    @test audit.luminosity.max_rel_error <= 2.0e-3
    @test audit.hydrostatic.max_rel_error <= 1.0e-6
    @test audit.transport.max_rel_error <= 1.0e-6
    @test isfinite(audit.luminosity.max_abs_error)
    @test isfinite(audit.luminosity.max_rel_error)
    @test jacobian[row, log_temperature_column] ≈ -dm_g * dε_total_dlnT atol = 1.0e-6 rtol = 1.0e-4
    @test jacobian[row, log_density_column] ≈ -dm_g * dε_total_dlnρ atol = 1.0e-6 rtol = 1.0e-4
end
