"""
    AnalyticalNuclear(; include_pp=true, include_cno=true, include_3alpha=false, include_screening=false)

Analytical PP-chain and CNO-cycle heating closure in linear cgs variables.
Triple-alpha is compiled in but disabled by default during the staged ASTRA
bootstrap migration. Screening can be enabled for PP and CNO through the
`include_screening` flag.
"""
const NUCLEAR_RATE_FLOOR = 1.0e-99
const ELEMENTARY_CHARGE_ESU = 4.803204712570263e-10
const ATOMIC_MASS_UNIT_CGS = 1.66053906660e-24

struct AnalyticalNuclear
    include_pp::Bool
    include_cno::Bool
    include_3alpha::Bool
    include_screening::Bool
end

AnalyticalNuclear(;
    include_pp::Bool = true,
    include_cno::Bool = true,
    include_3alpha::Bool = false,
    include_screening::Bool = false,
) = AnalyticalNuclear(include_pp, include_cno, include_3alpha, include_screening)

_nuclear_smooth_turnon(x::Float64, x0::Float64, width::Float64) =
    0.5 * (1.0 + tanh((x - x0) / width))

function _salpeter_screening_factor(
    Z_i::Real,
    Z_j::Real,
    density_g_cm3::Float64,
    temperature_k::Float64,
    composition::Composition,
)
    density_value = clip_positive(density_g_cm3)
    temperature_value = clip_positive(temperature_k)
    hydrogen_fraction = clip_positive(composition.X)
    helium_fraction = clip_positive(composition.Y)
    metal_fraction = clip_positive(composition.Z)

    electron_fraction = 0.5 * (1.0 + hydrogen_fraction)
    electron_density = density_value * electron_fraction / ATOMIC_MASS_UNIT_CGS

    ion_terms = hydrogen_fraction + 0.25 * helium_fraction + metal_fraction / 16.0
    ion_density = density_value * ion_terms / ATOMIC_MASS_UNIT_CGS
    z2_bar = (
        hydrogen_fraction * 1.0 +
        0.25 * helium_fraction * 4.0 +
        (metal_fraction / 16.0) * 64.0
    ) / clip_positive(ion_terms)

    screen_density = electron_density + ion_density * z2_bar
    debye_length = sqrt(
        BOLTZMANN_CONSTANT_CGS * temperature_value /
        (4.0 * π * screen_density * ELEMENTARY_CHARGE_ESU^2)
    )
    h_weak =
        Float64(Z_i) * Float64(Z_j) * ELEMENTARY_CHARGE_ESU^2 /
        (BOLTZMANN_CONSTANT_CGS * temperature_value * debye_length)

    h_safe = min(h_weak, log(10.0))
    cutoff = 0.5 * (1.0 + tanh((log10(density_value) + 5.0) / 2.0))
    factor = 1.0 + (exp(h_safe) - 1.0) * cutoff
    return clamp(factor, 1.0, 10.0)
end

function _pp_heating_rate(
    density_g_cm3::Float64,
    temperature_k::Float64,
    composition::Composition,
    screening_factor::Float64,
)
    temperature_mk = temperature_k / 1.0e6
    g_11 =
        1.0 +
        0.0123 * temperature_mk^(1.0 / 3.0) +
        0.0109 * temperature_mk^(2.0 / 3.0) +
        9.38e-4 * temperature_mk
    smooth_pp = max(_nuclear_smooth_turnon(temperature_mk, 4.0, 1.0), NUCLEAR_RATE_FLOOR)

    ln_eps_pp =
        log(2.38e6) +
        log(clip_positive(density_g_cm3)) +
        2.0 * log(clip_positive(composition.X)) -
        (2.0 / 3.0) * log(clip_positive(temperature_mk)) -
        33.80 / temperature_mk^(1.0 / 3.0) +
        log(g_11) +
        log(clip_positive(screening_factor)) +
        log(smooth_pp)
    return exp(max(ln_eps_pp, log(NUCLEAR_RATE_FLOOR)))
end

function _cno_heating_rate(
    density_g_cm3::Float64,
    temperature_k::Float64,
    composition::Composition,
    screening_factor::Float64,
)
    temperature_mk = temperature_k / 1.0e6
    cno_metal_fraction = max(0.7 * composition.Z, NUCLEAR_RATE_FLOOR)
    smooth_cno = max(_nuclear_smooth_turnon(temperature_mk, 15.0, 3.0), NUCLEAR_RATE_FLOOR)

    ln_eps_cno =
        log(8.67e25) +
        log(clip_positive(density_g_cm3)) +
        log(clip_positive(composition.X)) +
        log(cno_metal_fraction) -
        (2.0 / 3.0) * log(clip_positive(temperature_mk)) -
        152.28 / temperature_mk^(1.0 / 3.0) +
        log(clip_positive(screening_factor)) +
        log(smooth_cno)
    return exp(max(ln_eps_cno, log(NUCLEAR_RATE_FLOOR)))
end

function _triple_alpha_heating_rate(
    density_g_cm3::Float64,
    temperature_k::Float64,
    composition::Composition,
)
    temperature_gk = temperature_k / 1.0e9
    smooth_3alpha =
        max(_nuclear_smooth_turnon(temperature_gk, 0.1, 0.03), NUCLEAR_RATE_FLOOR)

    ln_eps_3alpha =
        log(5.1e8) +
        2.0 * log(clip_positive(density_g_cm3)) +
        3.0 * log(clip_positive(composition.Y)) -
        3.0 * log(clip_positive(temperature_gk)) -
        4.4 / temperature_gk +
        log(smooth_3alpha)
    return exp(max(ln_eps_3alpha, log(NUCLEAR_RATE_FLOOR)))
end

function (nuclear::AnalyticalNuclear)(
    density_g_cm3::Real,
    temperature_k::Real,
    composition::Composition,
)
    density_value = clip_positive(density_g_cm3)
    temperature_value = clip_positive(temperature_k)
    pp_screening_factor =
        nuclear.include_screening ? _salpeter_screening_factor(1, 1, density_value, temperature_value, composition) : 1.0
    cno_screening_factor =
        nuclear.include_screening ? _salpeter_screening_factor(7, 1, density_value, temperature_value, composition) : 1.0

    total_energy_rate_erg_g_s = 0.0
    if nuclear.include_pp
        total_energy_rate_erg_g_s += _pp_heating_rate(
            density_value,
            temperature_value,
            composition,
            pp_screening_factor,
        )
    end
    if nuclear.include_cno
        total_energy_rate_erg_g_s += _cno_heating_rate(
            density_value,
            temperature_value,
            composition,
            cno_screening_factor,
        )
    end
    if nuclear.include_3alpha
        total_energy_rate_erg_g_s +=
            _triple_alpha_heating_rate(density_value, temperature_value, composition)
    end

    return (
        energy_rate_erg_g_s = clip_positive(total_energy_rate_erg_g_s),
        source = :analytical_nuclear,
    )
end

function _centered_nuclear_temperature_derivative(
    nuclear::AnalyticalNuclear,
    density_g_cm3::Float64,
    temperature_k::Float64,
    composition::Composition,
)
    step_k = 1.0
    energy_plus =
        nuclear(density_g_cm3, temperature_k + step_k, composition).energy_rate_erg_g_s
    energy_minus =
        nuclear(density_g_cm3, clip_positive(temperature_k - step_k), composition).energy_rate_erg_g_s
    return (energy_plus - energy_minus) / (2.0 * step_k)
end

function _centered_nuclear_density_derivative(
    nuclear::AnalyticalNuclear,
    density_g_cm3::Float64,
    temperature_k::Float64,
    composition::Composition,
)
    step_g_cm3 = 1.0e-6
    energy_plus =
        nuclear(density_g_cm3 + step_g_cm3, temperature_k, composition).energy_rate_erg_g_s
    energy_minus =
        nuclear(clip_positive(density_g_cm3 - step_g_cm3), temperature_k, composition).energy_rate_erg_g_s
    return (energy_plus - energy_minus) / (2.0 * step_g_cm3)
end

function nuclear_temperature_derivative(
    nuclear::AnalyticalNuclear,
    density_g_cm3::Real,
    temperature_k::Real,
    composition::Composition,
)
    return _centered_nuclear_temperature_derivative(
        nuclear,
        clip_positive(density_g_cm3),
        clip_positive(temperature_k),
        composition,
    )
end

function nuclear_density_derivative(
    nuclear::AnalyticalNuclear,
    density_g_cm3::Real,
    temperature_k::Real,
    composition::Composition,
)
    return _centered_nuclear_density_derivative(
        nuclear,
        clip_positive(density_g_cm3),
        clip_positive(temperature_k),
        composition,
    )
end
