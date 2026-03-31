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

_radiative_transport_state(local_state::ConvectionLocalState) = ConvectionTransportState(
        :radiative,
        false,
        Float64(local_state.radiative_gradient),
        Float64(local_state.adiabatic_gradient),
        Float64(_ledoux_gradient(local_state)),
        Float64(local_state.radiative_gradient),
        Float64(local_state.radiative_gradient - _ledoux_gradient(local_state)),
        0.0,
        0.0,
        0.0,
    )

function _solve_positive_cubic_root(a0::Float64, rhs::Float64)
    isfinite(a0) && a0 > 0.0 || return NaN
    isfinite(rhs) && rhs > 0.0 || return NaN

    f(x) = a0 * x^3 + x^2 + x - rhs
    lower = 0.0
    upper = max(1.0, rhs)
    value_upper = f(upper)
    while value_upper <= 0.0
        upper *= 2.0
        isfinite(upper) || return NaN
        value_upper = f(upper)
        upper > 1.0e12 && break
    end
    value_upper > 0.0 || return NaN

    for _ in 1:80
        midpoint = 0.5 * (lower + upper)
        value_midpoint = f(midpoint)
        if value_midpoint > 0.0
            upper = midpoint
        else
            lower = midpoint
        end
    end

    return 0.5 * (lower + upper)
end

function _convective_transport_state(
    closure::BohmVitenseMLTConvection,
    local_state::ConvectionLocalState,
)
    ledoux_gradient = _ledoux_gradient(local_state)
    if local_state.radiative_gradient <= ledoux_gradient
        return _radiative_transport_state(local_state)
    end

    radius_cm = local_state.radius_cm
    enclosed_mass_g = local_state.enclosed_mass_g
    luminosity_erg_s = local_state.luminosity_erg_s
    pressure_dyn_cm2 = local_state.pressure_dyn_cm2
    temperature_k = local_state.temperature_k
    density_g_cm3 = local_state.density_g_cm3
    opacity_cm2_g = local_state.opacity_cm2_g
    specific_heat_erg_g_k = local_state.specific_heat_erg_g_k
    chi_rho = local_state.chi_rho
    chi_T = local_state.chi_T
    radiative_gradient = local_state.radiative_gradient
    Q = chi_T / chi_rho
    g = GRAVITATIONAL_CONSTANT_CGS * enclosed_mass_g / radius_cm^2
    pressure_scale_height = pressure_dyn_cm2 / (density_g_cm3 * g)
    mixing_length_cm = closure.alpha_MLT * pressure_scale_height
    radiative_conductivity =
        4.0 * RADIATION_CONSTANT_CGS * temperature_k^3 / (3.0 * opacity_cm2_g * density_g_cm3)
    convective_conductivity =
        specific_heat_erg_g_k * g * mixing_length_cm^2 * density_g_cm3 /
        9.0 * sqrt(Q * density_g_cm3 / (2.0 * pressure_dyn_cm2))

    a0 = 9.0 / 4.0
    A = convective_conductivity / radiative_conductivity
    B_cubed = (A^2 / a0) * (radiative_gradient - ledoux_gradient)
    gamma = _solve_positive_cubic_root(a0, a0 * B_cubed)

    zeta = clamp(gamma^3 / B_cubed, 0.0, 1.0)
    active_gradient =
        (1.0 - zeta) * radiative_gradient + zeta * ledoux_gradient
    superadiabatic_excess = active_gradient - ledoux_gradient
    convective_velocity_cm_s =
        closure.alpha_MLT * sqrt(Q * pressure_dyn_cm2 / (8.0 * density_g_cm3)) * gamma / A
    total_flux_erg_cm2_s = luminosity_erg_s / (4.0 * π * radius_cm^2)
    radiative_flux_erg_cm2_s =
        radiative_conductivity * temperature_k / pressure_scale_height * active_gradient
    convective_flux_fraction = clamp(
        1.0 - radiative_flux_erg_cm2_s / total_flux_erg_cm2_s,
        0.0,
        1.0,
    )

    return ConvectionTransportState(
        :convective,
        false,
        radiative_gradient,
        local_state.adiabatic_gradient,
        ledoux_gradient,
        active_gradient,
        superadiabatic_excess,
        gamma,
        convective_velocity_cm_s,
        convective_flux_fraction,
    )
end

function (closure::BohmVitenseMLTConvection)(local_state::ConvectionLocalState)
    return _convective_transport_state(closure, local_state)
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
