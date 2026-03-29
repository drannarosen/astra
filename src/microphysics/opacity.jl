struct KramersOpacity end

function (opacity::KramersOpacity)(
    density_g_cm3::Real,
    temperature_k::Real,
    composition::Composition,
)
    metallicity_factor = max(composition.Z, 1.0e-3)
    κ = 4.0e25 * metallicity_factor * density_g_cm3 * temperature_k^(-3.5)
    return (opacity_cm2_g = clip_positive(κ), source = :kramers_toy)
end

function opacity_temperature_derivative(
    opacity::KramersOpacity,
    density_g_cm3::Real,
    temperature_k::Real,
    composition::Composition,
)
    κ = opacity(density_g_cm3, temperature_k, composition).opacity_cm2_g
    return -3.5 * κ / clip_positive(temperature_k)
end
