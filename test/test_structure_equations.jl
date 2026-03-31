@testset "structure equations" begin
    problem = ASTRA.build_toy_problem(n_cells = 6)
    model = initialize_state(problem)

    @test ASTRA.shell_volume_cm3(1.0, 2.0) ≈ (4.0 * π / 3.0) * (8.0 - 1.0)

    eos_state = ASTRA.cell_eos_state(problem, model, 1)
    @test eos_state.pressure_dyn_cm2 > 0.0
    @test 0.0 < eos_state.gas_pressure_fraction <= 1.0
    @test isfinite(eos_state.adiabatic_gradient)
    @test isfinite(eos_state.specific_heat_erg_g_k)
    @test isfinite(eos_state.chi_rho)
    @test isfinite(eos_state.chi_T)

    degenerate_eos = ASTRA.Microphysics.AnalyticalGasRadiationEOS(include_degeneracy = true)
    degenerate_problem = ASTRA.StructureProblem(
        problem.formulation,
        problem.parameters,
        problem.composition,
        problem.grid,
        ASTRA.MicrophysicsBundle(
            degenerate_eos,
            problem.microphysics.opacity,
            problem.microphysics.nuclear,
            problem.microphysics.convection,
        ),
        problem.solver,
    )
    degenerate_state = ASTRA.cell_eos_state(degenerate_problem, model, 1)
    @test degenerate_state.pressure_dyn_cm2 >= eos_state.pressure_dyn_cm2
    @test isfinite(degenerate_state.chi_rho)
    @test isfinite(degenerate_state.chi_T)

    κ_state = ASTRA.cell_opacity_state(problem, model, 1)
    ε_state = ASTRA.cell_nuclear_state(problem, model, 1)
    @test κ_state.opacity_cm2_g > 0.0
    @test κ_state.source == :analytical_opacity
    @test ε_state.energy_rate_erg_g_s >= 0.0
    @test ε_state.source == :analytical_nuclear

    ∇rad = ASTRA.radiative_temperature_gradient(problem, model, 1)
    @test isfinite(∇rad)
    @test ∇rad >= 0.0

    transport_state = ASTRA.cell_transport_state(problem, model, 1)
    @test isfinite(transport_state.active_gradient)
    @test isfinite(transport_state.radiative_gradient)
    @test isfinite(transport_state.ledoux_gradient)
    @test transport_state.active_gradient <= transport_state.radiative_gradient

    convective_state = ASTRA.Microphysics.ConvectionLocalState(
        1.0e10,
        1.0e33,
        1.0e33,
        eos_state.pressure_dyn_cm2,
        exp(model.structure.log_temperature_cell_k[1]),
        exp(model.structure.log_density_cell_g_cm3[1]),
        κ_state.opacity_cm2_g,
        eos_state.specific_heat_erg_g_k,
        eos_state.chi_rho,
        eos_state.chi_T,
        eos_state.adiabatic_gradient,
        max(eos_state.adiabatic_gradient + 0.2, 0.8),
        0.0,
    )
    convective_result = problem.microphysics.convection(convective_state)
    @test convective_result.transport_regime == :convective
    @test convective_result.active_gradient < convective_result.radiative_gradient
end
