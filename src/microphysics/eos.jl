struct IdealGasRadiationEOS end

mean_molecular_weight(composition::Composition) =
    1.0 / (2.0 * composition.X + 0.75 * composition.Y + 0.5 * composition.Z)

function (eos::IdealGasRadiationEOS)(
    density_g_cm3::Real,
    temperature_k::Real,
    composition::Composition,
)
    mu = mean_molecular_weight(composition)
    pressure_gas = density_g_cm3 * BOLTZMANN_CONSTANT_CGS * temperature_k / (mu * HYDROGEN_MASS_CGS)
    pressure_radiation = (RADIATION_CONSTANT_CGS * temperature_k^4) / 3.0
    pressure_total = pressure_gas + pressure_radiation
    gas_pressure_fraction = pressure_gas / clip_positive(pressure_total)
    return (
        pressure_dyn_cm2 = pressure_total,
        gas_pressure_fraction = gas_pressure_fraction,
        adiabatic_gradient = 0.4,
        specific_heat_erg_g_k = 2.5 * BOLTZMANN_CONSTANT_CGS / (mu * HYDROGEN_MASS_CGS),
    )
end

function pressure_temperature_derivative(
    eos::IdealGasRadiationEOS,
    density_g_cm3::Real,
    temperature_k::Real,
    composition::Composition,
)
    mu = mean_molecular_weight(composition)
    gas_term =
        density_g_cm3 * BOLTZMANN_CONSTANT_CGS / (mu * HYDROGEN_MASS_CGS)
    radiation_term = 4.0 * RADIATION_CONSTANT_CGS * temperature_k^3 / 3.0
    return gas_term + radiation_term
end
