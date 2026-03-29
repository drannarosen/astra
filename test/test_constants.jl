@testset "constants" begin
    @test isapprox(ASTRA.GRAVITATIONAL_CONSTANT_CGS, 6.67430e-8; rtol = 1e-8)
    @test ASTRA.SOLAR_MASS_G > 1.0e33
    @test ASTRA.SOLAR_RADIUS_CM > 1.0e10
    @test ASTRA.SOLAR_LUMINOSITY_ERG_S > 1.0e33
    @test ASTRA.RADIATION_CONSTANT_CGS > 0.0
end
