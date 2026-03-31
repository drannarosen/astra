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

    excess = radiative_gradient - ledoux_gradient
    active_gradient = ledoux_gradient + 0.5 * excess
    convective_velocity_cm_s =
        1.0e5 *
        closure.alpha_MLT *
        Float64(1.0 + excess) *
        max(1.0, local_state.temperature_k / 1.0e6)
    convective_flux_fraction = clamp(excess / (1.0 + excess), 0.0, 1.0)

    return ConvectionTransportState(
        :convective,
        false,
        radiative_gradient,
        Float64(local_state.adiabatic_gradient),
        ledoux_gradient,
        active_gradient,
        active_gradient - ledoux_gradient,
        excess,
        convective_velocity_cm_s,
        convective_flux_fraction,
    )
end

function (closure::BohmVitenseMLTConvection)(local_state::ConvectionLocalState)
    return _convective_transport_state(closure, local_state)
end

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
