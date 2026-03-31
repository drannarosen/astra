"""
    ConvectionLocalState(...)

Immutable local state passed from numerics into the convection closure.
"""
struct ConvectionLocalState
    radius_cm::Float64
    enclosed_mass_g::Float64
    luminosity_erg_s::Float64
    pressure_dyn_cm2::Float64
    temperature_k::Float64
    density_g_cm3::Float64
    opacity_cm2_g::Float64
    specific_heat_erg_g_k::Float64
    chi_rho::Float64
    chi_T::Float64
    adiabatic_gradient::Float64
    radiative_gradient::Float64
    ledoux_composition_term::Float64
end

"""
    ConvectionTransportState(...)

Typed output from the local convection closure.
"""
struct ConvectionTransportState
    transport_regime::Symbol
    guarded::Bool
    radiative_gradient::Float64
    adiabatic_gradient::Float64
    ledoux_gradient::Float64
    active_gradient::Float64
    superadiabatic_excess::Float64
    convective_efficiency::Float64
    convective_velocity_cm_s::Float64
    convective_flux_fraction::Float64
end

"""
    BohmVitenseMLTConvection(alpha_MLT)

Optically thick local MLT convection closure with fixed mixing-length scale.
"""
struct BohmVitenseMLTConvection
    alpha_MLT::Float64

    function BohmVitenseMLTConvection(alpha_MLT::Real)
        alpha_value = Float64(alpha_MLT)
        alpha_value > 0.0 || throw(ArgumentError("alpha_MLT must be positive."))
        return new(alpha_value)
    end
end

struct SchwarzschildConvectionHook end

_ledoux_gradient(local_state::ConvectionLocalState) =
    local_state.adiabatic_gradient + local_state.ledoux_composition_term

_positive_finite(value::Real) = isfinite(value) && Float64(value) > 0.0

_radiative_transport_state(local_state::ConvectionLocalState) = ConvectionTransportState(
    :radiative,
    false,
    Float64(local_state.radiative_gradient),
    Float64(local_state.adiabatic_gradient),
    Float64(_ledoux_gradient(local_state)),
    Float64(local_state.radiative_gradient),
    0.0,
    0.0,
    0.0,
    0.0,
)

_guarded_radiative_transport_state(local_state::ConvectionLocalState) = ConvectionTransportState(
    :radiative,
    true,
    Float64(local_state.radiative_gradient),
    Float64(local_state.adiabatic_gradient),
    Float64(_ledoux_gradient(local_state)),
    Float64(local_state.radiative_gradient),
    0.0,
    0.0,
    0.0,
    0.0,
)

function _convective_transport_state(
    closure::BohmVitenseMLTConvection,
    local_state::ConvectionLocalState,
)
    ledoux_gradient = _ledoux_gradient(local_state)
    radiative_gradient = Float64(local_state.radiative_gradient)

    if radiative_gradient <= ledoux_gradient
        return _radiative_transport_state(local_state)
    end

    pressure_dyn_cm2 = Float64(local_state.pressure_dyn_cm2)
    temperature_k = Float64(local_state.temperature_k)
    density_g_cm3 = Float64(local_state.density_g_cm3)
    opacity_cm2_g = Float64(local_state.opacity_cm2_g)
    specific_heat_erg_g_k = Float64(local_state.specific_heat_erg_g_k)
    chi_rho = Float64(local_state.chi_rho)
    chi_T = Float64(local_state.chi_T)
    radius_cm = Float64(local_state.radius_cm)
    enclosed_mass_g = Float64(local_state.enclosed_mass_g)
    luminosity_erg_s = Float64(local_state.luminosity_erg_s)

    required_positive = (
        pressure_dyn_cm2,
        temperature_k,
        density_g_cm3,
        opacity_cm2_g,
        specific_heat_erg_g_k,
        chi_rho,
        chi_T,
        radius_cm,
        enclosed_mass_g,
        luminosity_erg_s,
    )
    all(_positive_finite, required_positive) || return _guarded_radiative_transport_state(local_state)

    Q = chi_T / chi_rho
    _positive_finite(Q) || return _guarded_radiative_transport_state(local_state)

    gravity_cgs = GRAVITATIONAL_CONSTANT_CGS * enclosed_mass_g / radius_cm^2
    _positive_finite(gravity_cgs) || return _guarded_radiative_transport_state(local_state)

    pressure_scale_height_cm = pressure_dyn_cm2 / (density_g_cm3 * gravity_cgs)
    _positive_finite(pressure_scale_height_cm) ||
        return _guarded_radiative_transport_state(local_state)

    mixing_length_cm = closure.alpha_MLT * pressure_scale_height_cm
    _positive_finite(mixing_length_cm) || return _guarded_radiative_transport_state(local_state)

    radiative_conductivity =
        4.0 * RADIATION_CONSTANT_CGS * temperature_k^3 /
        (3.0 * opacity_cm2_g * density_g_cm3)
    _positive_finite(radiative_conductivity) ||
        return _guarded_radiative_transport_state(local_state)

    convective_conductivity =
        (
            specific_heat_erg_g_k *
            gravity_cgs *
            mixing_length_cm^2 *
            density_g_cm3 /
            9.0
        ) * sqrt(Q * density_g_cm3 / (2.0 * pressure_dyn_cm2))
    _positive_finite(convective_conductivity) ||
        return _guarded_radiative_transport_state(local_state)

    a0 = 9.0 / 4.0
    conductivity_ratio = convective_conductivity / radiative_conductivity
    _positive_finite(conductivity_ratio) || return _guarded_radiative_transport_state(local_state)

    B_cubed = (conductivity_ratio^2 / a0) * (radiative_gradient - ledoux_gradient)
    _positive_finite(B_cubed) || return _guarded_radiative_transport_state(local_state)

    convective_efficiency = _solve_positive_cubic_root(a0, B_cubed)
    _positive_finite(convective_efficiency) ||
        return _guarded_radiative_transport_state(local_state)

    zeta = clamp(convective_efficiency^3 / B_cubed, 0.0, 1.0)
    active_gradient =
        (1.0 - zeta) * radiative_gradient + zeta * ledoux_gradient
    isfinite(active_gradient) || return _guarded_radiative_transport_state(local_state)

    convective_velocity_cm_s =
        closure.alpha_MLT *
        sqrt(Q * pressure_dyn_cm2 / (8.0 * density_g_cm3)) *
        convective_efficiency /
        conductivity_ratio
    _positive_finite(convective_velocity_cm_s) ||
        return _guarded_radiative_transport_state(local_state)

    total_flux_erg_cm2_s = luminosity_erg_s / (4.0 * π * radius_cm^2)
    _positive_finite(total_flux_erg_cm2_s) || return _guarded_radiative_transport_state(local_state)

    radiative_flux_erg_cm2_s =
        radiative_conductivity * temperature_k / pressure_scale_height_cm * active_gradient
    isfinite(radiative_flux_erg_cm2_s) || return _guarded_radiative_transport_state(local_state)
    convective_flux_fraction = clamp(
        1.0 - radiative_flux_erg_cm2_s / total_flux_erg_cm2_s,
        0.0,
        1.0,
    )
    isfinite(convective_flux_fraction) || return _guarded_radiative_transport_state(local_state)

    return ConvectionTransportState(
        :convective,
        false,
        radiative_gradient,
        Float64(local_state.adiabatic_gradient),
        ledoux_gradient,
        active_gradient,
        active_gradient - ledoux_gradient,
        convective_efficiency,
        convective_velocity_cm_s,
        convective_flux_fraction,
    )
end

function _solve_positive_cubic_root(a0::Float64, B_cubed::Float64)
    _positive_finite(a0) || return NaN
    _positive_finite(B_cubed) || return NaN

    f(gamma) = a0 * gamma^3 + gamma^2 + gamma - a0 * B_cubed

    lower = 0.0
    upper = max(1.0, B_cubed)
    while f(upper) <= 0.0
        upper *= 2.0
        _positive_finite(upper) || return NaN
    end

    for _ in 1:80
        midpoint = 0.5 * (lower + upper)
        if f(midpoint) <= 0.0
            lower = midpoint
        else
            upper = midpoint
        end
    end

    return 0.5 * (lower + upper)
end

function (closure::BohmVitenseMLTConvection)(local_state::ConvectionLocalState)
    return _convective_transport_state(closure, local_state)
end

# Transitional legacy-interface support for the pre-Task-3 bundle call shape.
function (closure::BohmVitenseMLTConvection)(
    radiative_gradient::Real,
    eos_state,
    opacity_state,
)
    adiabatic_gradient = Float64(eos_state.adiabatic_gradient)
    radiative_gradient_value = Float64(radiative_gradient)
    if radiative_gradient_value <= adiabatic_gradient
        return ConvectionTransportState(
            :radiative,
            false,
            radiative_gradient_value,
            adiabatic_gradient,
            adiabatic_gradient,
            radiative_gradient_value,
            0.0,
            0.0,
            0.0,
            0.0,
        )
    end

    active_gradient = adiabatic_gradient + 0.5 * (radiative_gradient_value - adiabatic_gradient)
    excess = radiative_gradient_value - adiabatic_gradient
    convective_flux_fraction = clamp(
        excess / (1.0 + excess),
        0.0,
        1.0,
    )
    return ConvectionTransportState(
        :convective,
        false,
        radiative_gradient_value,
        adiabatic_gradient,
        adiabatic_gradient,
        active_gradient,
        active_gradient - adiabatic_gradient,
        excess,
        1.0e5 * closure.alpha_MLT * (1.0 + excess),
        convective_flux_fraction,
    )
end

function (hook::SchwarzschildConvectionHook)(
    radiative_gradient::Real,
    eos_state,
    opacity_state,
)
    regime = radiative_gradient > eos_state.adiabatic_gradient ? :convective : :radiative
    hint = regime == :convective ? eos_state.adiabatic_gradient : radiative_gradient
    return (transport_regime = regime, temperature_gradient_hint = Float64(hint))
end
