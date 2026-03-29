struct ProtonProtonToyNuclear end

function (nuclear::ProtonProtonToyNuclear)(
    density_g_cm3::Real,
    temperature_k::Real,
    composition::Composition,
)
    scaled_temperature = temperature_k / 1.0e6
    ε = 1.07e-7 * density_g_cm3 * composition.X^2 * scaled_temperature^4
    return (energy_rate_erg_g_s = clip_positive(ε), source = :pp_toy)
end
