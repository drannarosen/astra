const ELECTRON_REST_ENERGY_ERG = 8.1871057769e-7

"""
    AnalyticalOpacity(; include_kramers=true, include_h_minus=true, include_electron_scattering=true)

Analytical Rosseland-mean opacity closure with Kramers, H-minus, and electron
scattering components expressed directly in linear cgs variables.
"""
struct AnalyticalOpacity
    include_kramers::Bool
    include_h_minus::Bool
    include_electron_scattering::Bool
end

AnalyticalOpacity(;
    include_kramers::Bool = true,
    include_h_minus::Bool = true,
    include_electron_scattering::Bool = true,
) = AnalyticalOpacity(include_kramers, include_h_minus, include_electron_scattering)

function _kramers_opacity_component(
    density_g_cm3::Float64,
    temperature_k::Float64,
    composition::Composition,
)
    x = log10(temperature_k) - 4.0
    gaunt_factor = max(1.0, 1.226 + 0.0426 * x - 0.0157 * x^2 + 0.00243 * x^3)
    effective_metallicity = max(composition.Z, 1.0e-3)
    composition_factor = effective_metallicity * (1.0 + composition.X) / 2.0
    return 4.34e25 * composition_factor * density_g_cm3 * temperature_k^(-3.5) * gaunt_factor
end

function _h_minus_opacity_component(
    density_g_cm3::Float64,
    temperature_k::Float64,
    composition::Composition,
)
    mu = mean_molecular_weight(composition)
    gas_pressure_dyn_cm2 =
        density_g_cm3 * BOLTZMANN_CONSTANT_CGS * temperature_k / (mu * HYDROGEN_MASS_CGS)
    electron_mean_molecular_weight = 2.0 / (1.0 + composition.X)
    electron_pressure_dyn_cm2 = gas_pressure_dyn_cm2 * (mu / electron_mean_molecular_weight)

    ionization_temperature_k = 0.754 * 11605.0
    exponent = clamp(ionization_temperature_k / temperature_k, -200.0, 200.0)
    ionization_factor =
        exp(exponent) * (1.0 + 0.035 * sqrt(temperature_k) - 4.3e-4 * temperature_k)

    bound_free_component =
        1.1e-25 * electron_pressure_dyn_cm2 * temperature_k^(-4.5) * ionization_factor
    hydrogen_pressure_dyn_cm2 =
        composition.X * density_g_cm3 * BOLTZMANN_CONSTANT_CGS * temperature_k /
        HYDROGEN_MASS_CGS
    free_free_component =
        3.7e-38 * electron_pressure_dyn_cm2 * hydrogen_pressure_dyn_cm2 * temperature_k^(-3.5)

    log10_temperature = log10(temperature_k)
    weight_on = 0.5 * (1.0 + tanh((log10_temperature - log10(4000.0)) / 0.2))
    weight_off = 0.5 * (1.0 + tanh((log10(15000.0) - log10_temperature) / 0.3))
    return weight_on * weight_off * (bound_free_component + free_free_component)
end

function _electron_scattering_component(
    temperature_k::Float64,
    composition::Composition,
)
    baseline_opacity = 0.2 * (1.0 + composition.X)
    theta = BOLTZMANN_CONSTANT_CGS * temperature_k / ELECTRON_REST_ENERGY_ERG
    klein_nishina_correction = 1.0 / (1.0 + theta^0.86)
    return baseline_opacity * klein_nishina_correction
end

function (opacity::AnalyticalOpacity)(
    density_g_cm3::Real,
    temperature_k::Real,
    composition::Composition,
)
    density_value = clip_positive(density_g_cm3)
    temperature_value = clip_positive(temperature_k)

    total_opacity_cm2_g = 0.0
    if opacity.include_kramers
        total_opacity_cm2_g += max(
            0.0,
            _kramers_opacity_component(density_value, temperature_value, composition),
        )
    end
    if opacity.include_h_minus
        total_opacity_cm2_g += max(
            0.0,
            _h_minus_opacity_component(density_value, temperature_value, composition),
        )
    end
    if opacity.include_electron_scattering
        total_opacity_cm2_g += max(
            0.0,
            _electron_scattering_component(temperature_value, composition),
        )
    end

    return (opacity_cm2_g = clip_positive(total_opacity_cm2_g), source = :analytical_opacity)
end

function _centered_opacity_temperature_derivative(
    opacity::AnalyticalOpacity,
    density_g_cm3::Float64,
    temperature_k::Float64,
    composition::Composition,
)
    step_k = 1.0
    opacity_plus = opacity(density_g_cm3, temperature_k + step_k, composition).opacity_cm2_g
    opacity_minus =
        opacity(density_g_cm3, clip_positive(temperature_k - step_k), composition).opacity_cm2_g
    return (opacity_plus - opacity_minus) / (2.0 * step_k)
end

function _centered_opacity_density_derivative(
    opacity::AnalyticalOpacity,
    density_g_cm3::Float64,
    temperature_k::Float64,
    composition::Composition,
)
    step_g_cm3 = 1.0e-6
    opacity_plus = opacity(density_g_cm3 + step_g_cm3, temperature_k, composition).opacity_cm2_g
    opacity_minus =
        opacity(clip_positive(density_g_cm3 - step_g_cm3), temperature_k, composition).opacity_cm2_g
    return (opacity_plus - opacity_minus) / (2.0 * step_g_cm3)
end

function opacity_temperature_derivative(
    opacity::AnalyticalOpacity,
    density_g_cm3::Real,
    temperature_k::Real,
    composition::Composition,
)
    return _centered_opacity_temperature_derivative(
        opacity,
        clip_positive(density_g_cm3),
        clip_positive(temperature_k),
        composition,
    )
end

function opacity_density_derivative(
    opacity::AnalyticalOpacity,
    density_g_cm3::Real,
    temperature_k::Real,
    composition::Composition,
)
    return _centered_opacity_density_derivative(
        opacity,
        clip_positive(density_g_cm3),
        clip_positive(temperature_k),
        composition,
    )
end
