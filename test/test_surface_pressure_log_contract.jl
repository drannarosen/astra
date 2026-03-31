@testset "surface pressure log contract" begin
    mismatch = ASTRA.surface_pressure_log_mismatch(1.0e14, 5.0e13)

    @test mismatch ≈ log(2.0)
    @test mismatch ≈ ASTRA.surface_pressure_log_mismatch(1.0e20, 5.0e19)
    @test ASTRA.surface_pressure_log_mismatch(3.0e13, 3.0e13) ≈ 0.0 atol = 1.0e-12
end
