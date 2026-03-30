"""
    AnalyticalGasRadiationEOS(; include_coulomb=false, include_degeneracy=false)

Staged ideal-gas plus radiation EOS for the ASTRA bootstrap lane. Coulomb and
degeneracy flags are carried forward for later validation slices but remain
disabled in the default path.
"""
const ATOMIC_MASS_UNIT_CGS = 1.66053906660e-24
const ELECTRON_MASS_CGS = 9.1093837015e-28
const ELEMENTARY_CHARGE_ESU = 4.803204712570263e-10
const PLANCK_REDUCED_CGS = 1.054571817e-27

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

mean_molecular_weight_per_ion(composition::Composition) =
    1.0 / (composition.X + 0.25 * composition.Y + 0.0625 * composition.Z)

mean_molecular_weight_per_electron(composition::Composition) = 2.0 / (1.0 + composition.X)

function _paczynski_electron_pressure(
    density_g_cm3::Float64,
    temperature_k::Float64,
    mu_e::Float64,
)
    electron_density = clip_positive(density_g_cm3) / (mu_e * ATOMIC_MASS_UNIT_CGS)
    ideal_pressure =
        clip_positive(density_g_cm3) * BOLTZMANN_CONSTANT_CGS * clip_positive(temperature_k) /
        (mu_e * HYDROGEN_MASS_CGS)
    degeneracy_coefficient =
        (PLANCK_REDUCED_CGS^2 / (5.0 * ELECTRON_MASS_CGS)) * (3.0 * π^2)^(2.0 / 3.0)
    degeneracy_pressure = degeneracy_coefficient * electron_density^(5.0 / 3.0)
    return sqrt(ideal_pressure^2 + degeneracy_pressure^2)
end

function _debye_huckel_coulomb_correction(
    density_g_cm3::Float64,
    temperature_k::Float64,
    composition::Composition,
)
    density_value = clip_positive(density_g_cm3)
    temperature_value = clip_positive(temperature_k)
    mu_ion = mean_molecular_weight_per_ion(composition)
    ion_density = density_value / (mu_ion * ATOMIC_MASS_UNIT_CGS)
    ion_separation = (3.0 / (4.0 * π * ion_density))^(1.0 / 3.0)
    mean_square_charge = 1.0 + 3.0 * composition.Y
    coupling = mean_square_charge * ELEMENTARY_CHARGE_ESU^2 /
        (ion_separation * BOLTZMANN_CONSTANT_CGS * temperature_value)
    dh_prefactor = sqrt(3.0) / 2.0
    return -dh_prefactor * ion_density * BOLTZMANN_CONSTANT_CGS * temperature_value *
        coupling^(1.5)
end

function _pressure_state(
    eos::AnalyticalGasRadiationEOS,
    density_g_cm3::Float64,
    temperature_k::Float64,
    composition::Composition,
)
    density_value = clip_positive(density_g_cm3)
    temperature_value = clip_positive(temperature_k)
    mu = mean_molecular_weight(composition)
    mu_e = mean_molecular_weight_per_electron(composition)
    mu_ion = mean_molecular_weight_per_ion(composition)

    pressure_gas_ideal =
        density_value * BOLTZMANN_CONSTANT_CGS * temperature_value / (mu * HYDROGEN_MASS_CGS)
    pressure_electron_ideal =
        density_value * BOLTZMANN_CONSTANT_CGS * temperature_value / (mu_e * HYDROGEN_MASS_CGS)
    pressure_ions = pressure_gas_ideal - pressure_electron_ideal
    pressure_electron = eos.include_degeneracy ? _paczynski_electron_pressure(
        density_value,
        temperature_value,
        mu_e,
    ) : pressure_electron_ideal
    pressure_gas = pressure_ions + pressure_electron
    pressure_radiation = (RADIATION_CONSTANT_CGS * temperature_value^4) / 3.0
    pressure_coulomb = eos.include_coulomb ? _debye_huckel_coulomb_correction(
        density_value,
        temperature_value,
        composition,
    ) : 0.0

    pressure_raw = pressure_gas + pressure_radiation + pressure_coulomb
    pressure_total = max(pressure_raw, pressure_gas * 1.0e-10)

    return (
        pressure_total = pressure_total,
        pressure_gas = pressure_gas,
        pressure_radiation = pressure_radiation,
        pressure_coulomb = pressure_coulomb,
        mu = mu,
    )
end

function _pressure_temperature_derivative_core(
    eos::AnalyticalGasRadiationEOS,
    density_g_cm3::Float64,
    temperature_k::Float64,
    composition::Composition,
)
    density_value = clip_positive(density_g_cm3)
    temperature_value = clip_positive(temperature_k)

    if eos.include_degeneracy || eos.include_coulomb
        step_k = max(1.0e-6 * temperature_value, 1.0e-3)
        pressure_plus = _pressure_state(eos, density_value, temperature_value + step_k, composition).pressure_total
        pressure_minus = _pressure_state(
            eos,
            density_value,
            max(temperature_value - step_k, 1.0e-12),
            composition,
        ).pressure_total
        return (pressure_plus - pressure_minus) / (2.0 * step_k)
    end

    mu = mean_molecular_weight(composition)
    gas_term =
        density_value * BOLTZMANN_CONSTANT_CGS / (mu * HYDROGEN_MASS_CGS)
    radiation_term = 4.0 * RADIATION_CONSTANT_CGS * temperature_value^3 / 3.0
    return gas_term + radiation_term
end

function _pressure_density_derivative_core(
    eos::AnalyticalGasRadiationEOS,
    density_g_cm3::Float64,
    temperature_k::Float64,
    composition::Composition,
)
    density_value = clip_positive(density_g_cm3)
    temperature_value = clip_positive(temperature_k)

    if eos.include_degeneracy || eos.include_coulomb
        step_ρ = max(1.0e-6 * density_value, 1.0e-8)
        pressure_plus = _pressure_state(eos, density_value + step_ρ, temperature_value, composition).pressure_total
        pressure_minus = _pressure_state(
            eos,
            max(density_value - step_ρ, 1.0e-12),
            temperature_value,
            composition,
        ).pressure_total
        return (pressure_plus - pressure_minus) / (2.0 * step_ρ)
    end

    mu = mean_molecular_weight(composition)
    return BOLTZMANN_CONSTANT_CGS * temperature_value / (mu * HYDROGEN_MASS_CGS)
end

function (eos::AnalyticalGasRadiationEOS)(
    density_g_cm3::Real,
    temperature_k::Real,
    composition::Composition,
)
    density_value = clip_positive(density_g_cm3)
    temperature_value = clip_positive(temperature_k)
    state = _pressure_state(eos, density_value, temperature_value, composition)
    pressure_total = state.pressure_total
    pressure_gas = state.pressure_gas
    gas_pressure_fraction = pressure_gas / clip_positive(pressure_total)

    dP_dρ = _pressure_density_derivative_core(eos, density_value, temperature_value, composition)
    dP_dT =
        _pressure_temperature_derivative_core(eos, density_value, temperature_value, composition)
    chi_rho = density_value * dP_dρ / clip_positive(pressure_total)
    chi_T = temperature_value * dP_dT / clip_positive(pressure_total)

    specific_heat_cv =
        1.5 * BOLTZMANN_CONSTANT_CGS / (state.mu * HYDROGEN_MASS_CGS) +
        4.0 * RADIATION_CONSTANT_CGS * temperature_value^3 / density_value
    specific_heat_cp =
        specific_heat_cv +
        pressure_total * chi_T^2 /
        (density_value * temperature_value * max(chi_rho, 1.0e-10))
    adiabatic_gradient =
        pressure_total * chi_T /
        (density_value * temperature_value * specific_heat_cp * max(chi_rho, 1.0e-10))

    return (
        pressure_dyn_cm2 = pressure_total,
        gas_pressure_fraction = gas_pressure_fraction,
        adiabatic_gradient = adiabatic_gradient,
        specific_heat_erg_g_k = specific_heat_cp,
        chi_rho = chi_rho,
        chi_T = chi_T,
    )
end

function pressure_temperature_derivative(
    eos::AnalyticalGasRadiationEOS,
    density_g_cm3::Real,
    temperature_k::Real,
    composition::Composition,
)
    return _pressure_temperature_derivative_core(
        eos,
        clip_positive(density_g_cm3),
        clip_positive(temperature_k),
        composition,
    )
end

function pressure_density_derivative(
    eos::AnalyticalGasRadiationEOS,
    density_g_cm3::Real,
    temperature_k::Real,
    composition::Composition,
)
    return _pressure_density_derivative_core(
        eos,
        clip_positive(density_g_cm3),
        clip_positive(temperature_k),
        composition,
    )
end
