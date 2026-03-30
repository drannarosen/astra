"""
    AnalyticalGasRadiationEOS(; include_coulomb=false, include_degeneracy=false)

Staged ideal-gas plus radiation EOS for the ASTRA bootstrap lane. Coulomb and
degeneracy flags are carried forward for later validation slices but remain
disabled in the default path.
"""
struct AnalyticalGasRadiationEOS
    include_coulomb::Bool
    include_degeneracy::Bool
end

AnalyticalGasRadiationEOS(;
    include_coulomb::Bool = false,
    include_degeneracy::Bool = false,
) = AnalyticalGasRadiationEOS(include_coulomb, include_degeneracy)

mean_molecular_weight(composition::Composition) =
    1.0 / (2.0 * composition.X + 0.75 * composition.Y + 0.5 * composition.Z)

function (eos::AnalyticalGasRadiationEOS)(
    density_g_cm3::Real,
    temperature_k::Real,
    composition::Composition,
)
    density_value = clip_positive(density_g_cm3)
    temperature_value = clip_positive(temperature_k)
    mu = mean_molecular_weight(composition)

    pressure_gas =
        density_value * BOLTZMANN_CONSTANT_CGS * temperature_value / (mu * HYDROGEN_MASS_CGS)
    pressure_radiation = (RADIATION_CONSTANT_CGS * temperature_value^4) / 3.0
    pressure_total = pressure_gas + pressure_radiation
    gas_pressure_fraction = pressure_gas / clip_positive(pressure_total)

    χρ = gas_pressure_fraction
    χT = 4.0 - 3.0 * gas_pressure_fraction
    specific_heat_cv =
        1.5 * BOLTZMANN_CONSTANT_CGS / (mu * HYDROGEN_MASS_CGS) +
        4.0 * RADIATION_CONSTANT_CGS * temperature_value^3 / density_value
    specific_heat_cp =
        specific_heat_cv +
        pressure_total * χT^2 /
        (density_value * temperature_value * max(χρ, 1.0e-10))
    adiabatic_gradient =
        (8.0 - 6.0 * gas_pressure_fraction) /
        (32.0 - 24.0 * gas_pressure_fraction - 3.0 * gas_pressure_fraction^2)

    return (
        pressure_dyn_cm2 = pressure_total,
        gas_pressure_fraction = gas_pressure_fraction,
        adiabatic_gradient = adiabatic_gradient,
        specific_heat_erg_g_k = specific_heat_cp,
    )
end

function pressure_temperature_derivative(
    eos::AnalyticalGasRadiationEOS,
    density_g_cm3::Real,
    temperature_k::Real,
    composition::Composition,
)
    mu = mean_molecular_weight(composition)
    gas_term =
        clip_positive(density_g_cm3) * BOLTZMANN_CONSTANT_CGS / (mu * HYDROGEN_MASS_CGS)
    radiation_term = 4.0 * RADIATION_CONSTANT_CGS * clip_positive(temperature_k)^3 / 3.0
    return gas_term + radiation_term
end

function pressure_density_derivative(
    eos::AnalyticalGasRadiationEOS,
    density_g_cm3::Real,
    temperature_k::Real,
    composition::Composition,
)
    mu = mean_molecular_weight(composition)
    return BOLTZMANN_CONSTANT_CGS * clip_positive(temperature_k) / (mu * HYDROGEN_MASS_CGS)
end
