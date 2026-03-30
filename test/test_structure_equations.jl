@testset "structure equations" begin
    problem = ASTRA.build_toy_problem(n_cells = 6)
    model = initialize_state(problem)

    @test ASTRA.shell_volume_cm3(1.0, 2.0) ≈ (4.0 * π / 3.0) * (8.0 - 1.0)

    eos_state = ASTRA.cell_eos_state(problem, model, 1)
    @test eos_state.pressure_dyn_cm2 > 0.0
    @test 0.0 < eos_state.gas_pressure_fraction <= 1.0
    @test isfinite(eos_state.adiabatic_gradient)
    @test isfinite(eos_state.specific_heat_erg_g_k)

    κ_state = ASTRA.cell_opacity_state(problem, model, 1)
    ε_state = ASTRA.cell_nuclear_state(problem, model, 1)
    @test κ_state.opacity_cm2_g > 0.0
    @test κ_state.source == :analytical_opacity
    @test ε_state.energy_rate_erg_g_s >= 0.0
    @test ε_state.source == :analytical_nuclear

    ∇rad = ASTRA.radiative_temperature_gradient(problem, model, 1)
    @test isfinite(∇rad)
    @test ∇rad >= 0.0
end
