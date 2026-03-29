struct SchwarzschildConvectionHook end

function (hook::SchwarzschildConvectionHook)(
    radiative_gradient::Real,
    eos_state,
    opacity_state,
)
    regime = radiative_gradient > eos_state.adiabatic_gradient ? :convective : :radiative
    hint = regime == :convective ? eos_state.adiabatic_gradient : radiative_gradient
    return (transport_regime = regime, temperature_gradient_hint = Float64(hint))
end
