# Analytical Gas and Radiation EOS

ASTRA's current EOS is a staged analytical pressure decomposition, not a table lookup: gas pressure plus radiation pressure, with explicit local derivatives for the Newton solve.

## Current formula

The current closure is

$$
P(\rho, T, X, Y) = \frac{\rho k_B T}{\mu m_u} + \frac{a T^4}{3}
$$

where `rho` is density, `T` is temperature, `mu` is the mean molecular weight from composition, `m_u` is the hydrogen mass constant used in ASTRA, `k_B` is Boltzmann's constant, and `a` is the radiation constant.

This is the exact default pressure decomposition ASTRA uses today in `src/microphysics/eos.jl`.

Pedagogically, this is a good first EOS because each term answers a different physical question:

- the gas term says how much pressure the particles supply by thermal motion,
- the radiation term says how much pressure the trapped photon field supplies,
- the ratio between them tells us how compressible the fluid is and how the star responds to heating.

Flag-gated enrichments also exist in the same closure:

- Paczynski-style electron-pressure interpolation when `include_degeneracy = true`,
- Debye-Huckel Coulomb pressure correction when `include_coulomb = true`.

Those enrichments are validated as local analytical options, not promoted to the default path.

## Derivatives ASTRA uses

The EOS provides the derivative payloads the Jacobian and transport helper need:

ASTRA tracks the literal payload names `dP/dT` and `dP/drho` in the docs because those are the sensitivities future developers search for first.

$$
\frac{dP}{dT} = \frac{\rho k_B}{\mu m_u} + \frac{4 a T^3}{3}
$$

$$
\frac{dP}{d\rho} = \frac{k_B T}{\mu m_u}
$$

In code, these are the `pressure_temperature_derivative(...)` and `pressure_density_derivative(...)` helpers in `src/microphysics/eos.jl`.

The staged closure now also returns `chi_rho` and `chi_T`, because ASTRA's evolution-owned gravothermal helper needs those thermodynamic response terms when `eps_grav` is evaluated from the cp-form identity. In the default gas-plus-radiation limit, those response terms reduce to the familiar beta-based identities. In the flag-gated branches, ASTRA uses the EOS's returned `chi_rho` and `chi_T` directly instead of pretending the ideal-gas identities still hold.

## How it enters ASTRA

The EOS pressure is used directly in the hydrostatic row and in the transport helper. ASTRA does not store pressure as a separate solve-owned variable; it evaluates the EOS from the local cell state whenever a residual or derivative needs it.

The method-side realization is documented in [Residual Assembly](../../methods/residual-assembly.md) and [Jacobian Construction](../../methods/jacobian-construction.md), where the EOS sensitivities enter the hydrostatic and transport rows.

The EOS also supplies a beta-dependent `adiabatic_gradient` and a beta-based specific heat at constant pressure. The flagged Paczynski and Debye-Huckel branches are real analytical options now, but both remain disabled in the default bootstrap path and are therefore staged enrichments rather than default thermodynamics.

## What is deferred

Real EOS tables, partial ionization, entropy-authoritative inversion, and composition-rich thermodynamics are deferred. Degeneracy and Coulomb corrections remain flag-gated in the default path. This page documents the staged analytical closure ASTRA actually solves with today, not the closure we want for a production stellar model.
