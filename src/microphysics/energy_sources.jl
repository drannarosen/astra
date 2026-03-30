"""
    eps_grav_from_cp(; kwargs...)

Compute the gravothermal source term in cp form from linear-cgs thermodynamic
derivatives. The helper stays internal to the analytical source lane and does
not widen the public microphysics payload.
"""
function eps_grav_from_cp(;
    temperature_k::Real,
    specific_heat_erg_g_k::Real,
    adiabatic_gradient::Real,
    chi_temperature::Real,
    chi_density::Real,
    dlog_temperature_dt::Real,
    dlog_density_dt::Real,
)
    temperature_value = clip_positive(temperature_k)
    specific_heat_value = clip_positive(specific_heat_erg_g_k)
    adiabatic_gradient_value = Float64(adiabatic_gradient)
    chi_temperature_value = Float64(chi_temperature)
    chi_density_value = Float64(chi_density)
    dlog_temperature_dt_value = Float64(dlog_temperature_dt)
    dlog_density_dt_value = Float64(dlog_density_dt)

    return -temperature_value * specific_heat_value * (
        (1.0 - adiabatic_gradient_value * chi_temperature_value) * dlog_temperature_dt_value -
        adiabatic_gradient_value * chi_density_value * dlog_density_dt_value
    )
end

"""
    analytical_neutrino_loss_rate(density_g_cm3, temperature_k, composition)

Return a finite, analytical thermal-neutrino loss rate in linear cgs variables.
This is a minimal monotone slice, not a full Itoh-process port.
"""
function analytical_neutrino_loss_rate(
    density_g_cm3::Real,
    temperature_k::Real,
    composition::Composition,
)
    density_value = clip_positive(density_g_cm3)
    temperature_value = clip_positive(temperature_k)
    temperature_gk = temperature_value / 1.0e9
    electron_fraction = composition.X + 0.5 * composition.Y + 0.5 * composition.Z
    composition_factor = 0.5 + 0.5 * clip_positive(electron_fraction)
    density_factor = sqrt(density_value / 1.0e2)
    thermal_factor = temperature_gk^6 * (1.0 + 0.1 * temperature_gk^3)
    return 1.0e-25 * density_factor * composition_factor * thermal_factor
end

function _cell_composition(model::StellarModel, k::Int)
    return Composition(
        model.composition.hydrogen_mass_fraction_cell[k],
        model.composition.helium_mass_fraction_cell[k],
        model.composition.metal_mass_fraction_cell[k],
    )
end

function _history_gravothermal_rate(
    problem::StructureProblem,
    model::StellarModel,
    k::Int,
    density_g_cm3::Real,
    temperature_k::Real,
    composition::Composition,
)
    prev_temperature = model.evolution.previous_log_temperature_cell_k
    prev_density = model.evolution.previous_log_density_cell_g_cm3
    if isnothing(prev_temperature) || isnothing(prev_density)
        return 0.0, :no_history
    end

    dt_s = Float64(model.evolution.timestep_s)
    dt_s > 0.0 || throw(
        ArgumentError("Evolution history requires a positive timestep_s for eps_grav evaluation."),
    )
    current_log_temperature = model.structure.log_temperature_cell_k[k]
    current_log_density = model.structure.log_density_cell_g_cm3[k]
    dlog_temperature_dt = (current_log_temperature - prev_temperature[k]) / dt_s
    dlog_density_dt = (current_log_density - prev_density[k]) / dt_s
    eos_state = problem.microphysics.eos(density_g_cm3, temperature_k, composition)
    chi_density = eos_state.gas_pressure_fraction
    chi_temperature = 4.0 - 3.0 * chi_density
    eps_grav = eps_grav_from_cp(
        temperature_k = temperature_k,
        specific_heat_erg_g_k = eos_state.specific_heat_erg_g_k,
        adiabatic_gradient = eos_state.adiabatic_gradient,
        chi_temperature = chi_temperature,
        chi_density = chi_density,
        dlog_temperature_dt = dlog_temperature_dt,
        dlog_density_dt = dlog_density_dt,
    )
    return eps_grav, :evolution_history
end

"""
    energy_source_terms(problem, model, k)

Assemble the analytical source terms used by the luminosity row.
"""
function energy_source_terms(problem::StructureProblem, model::StellarModel, k::Int)
    composition = _cell_composition(model, k)
    density_g_cm3 = exp(model.structure.log_density_cell_g_cm3[k])
    temperature_k = exp(model.structure.log_temperature_cell_k[k])

    nuclear_state = problem.microphysics.nuclear(density_g_cm3, temperature_k, composition)
    eps_nuc_erg_g_s = nuclear_state.energy_rate_erg_g_s
    eps_nu_erg_g_s = analytical_neutrino_loss_rate(density_g_cm3, temperature_k, composition)
    eps_grav_erg_g_s, eps_grav_owner = _history_gravothermal_rate(
        problem,
        model,
        k,
        density_g_cm3,
        temperature_k,
        composition,
    )
    eps_total_erg_g_s = eps_nuc_erg_g_s + eps_grav_erg_g_s - eps_nu_erg_g_s

    return (
        eps_nuc_erg_g_s = eps_nuc_erg_g_s,
        eps_grav_erg_g_s = eps_grav_erg_g_s,
        eps_nu_erg_g_s = eps_nu_erg_g_s,
        eps_total_erg_g_s = eps_total_erg_g_s,
        eps_grav_owner = eps_grav_owner,
    )
end
