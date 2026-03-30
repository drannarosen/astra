# Opacity

Opacity is the local rule that tells ASTRA how hard it is for radiation to move through stellar matter. If the EOS tells us how matter pushes back mechanically, opacity tells us how matter resists radiative energy transport.

For a new student, opacity can feel abstract because it is not directly visible in a star the way pressure or luminosity is. But it is one of the most important control knobs in stellar structure. Change the opacity, and you change how steep the temperature gradient must become to carry the same luminosity.

## Why opacity matters

In the radiative transport regime, the temperature gradient depends directly on opacity. Large opacity means photons are trapped more effectively, so the star needs a steeper temperature gradient to move the same energy flux outward. Small opacity means radiation can escape more easily, so the gradient can be shallower.

This is why opacity is not just a lookup detail. It affects:

- radiative transport,
- convective stability through `nabla_rad`,
- the Jacobian entries tied to transport,
- and therefore the convergence behavior of the nonlinear solve.

## Current ASTRA implementation

ASTRA currently uses a staged analytical opacity closure with three additive pieces:

$$
\kappa = \kappa_\mathrm{Kramers} + \kappa_{H^-} + \kappa_\mathrm{es}.
$$

That sum is deliberately explicit. Each term corresponds to a different physical way in which matter interacts with radiation:

- Kramers opacity represents bound-free and free-free absorption in hot ionized gas.
- H-minus opacity is a cool-atmosphere mechanism tied to loosely bound electrons.
- Electron scattering represents photons being redirected by free electrons.

### Physical intuition

These three pieces dominate in different regions of a star.

- In hot, ionized interiors, Kramers-like absorption is often the leading analytical term.
- In cool envelopes and atmosphere-like conditions, H-minus can become very important.
- Electron scattering is present almost everywhere ionized electrons exist, but it often dominates only when true absorption is weak.

This is a useful teaching closure because students can learn to associate different opacity mechanisms with different thermodynamic regimes instead of treating `kappa` as an opaque black box.

### Exact staged formulas

ASTRA's present analytical opacity uses the following ingredients.

The Kramers-like term scales as

$$
\kappa_\mathrm{Kramers}
=
4.34\times 10^{25}
\left[\frac{Z_\mathrm{eff}(1+X)}{2}\right]
\rho T^{-3.5} \bar g(T),
$$

where $\bar g(T)$ is a temperature-dependent Gaunt-factor correction and $Z_\mathrm{eff}$ is floored to a small positive value so the analytical branch remains well-behaved even in very metal-poor trial states.

The H-minus piece is a simplified proxy built from bound-free and free-free contributions, multiplied by a smooth temperature window so it only operates in the cool regime where that physics is relevant.

The electron-scattering term is

$$
\kappa_\mathrm{es}
=
0.2(1+X)\, f_\mathrm{KN}(T),
$$

where the current analytical correction

$$
f_\mathrm{KN}(T) = \frac{1}{1+\theta^{0.86}}
$$

softens the Thomson limit at high thermal energies.

The exact staged equations are collected in [Analytical Opacity Components](opacity/analytical-opacity.md).

## Derivatives ASTRA uses

ASTRA tracks the literal payload names `dκ/dT` and `dκ/drho` because those are the sensitivities future developers search for first.

In the current bootstrap lane, ASTRA does **not** hand-code analytical derivatives for the full composite opacity. Instead it differentiates the exact staged closure with explicit centered local finite differences:

$$
\frac{d\kappa}{dT}
\approx
\frac{\kappa(\rho, T+\Delta T)-\kappa(\rho, T-\Delta T)}{2\Delta T},
$$

$$
\frac{d\kappa}{d\rho}
\approx
\frac{\kappa(\rho+\Delta \rho, T)-\kappa(\rho-\Delta \rho, T)}{2\Delta \rho}.
$$

That ownership choice is important. ASTRA is not differentiating a simplified surrogate of the opacity. It is differentiating the exact smoothed analytical opacity it solves with, including the H-minus activation window.

## Numerical realization in ASTRA

Opacity enters the radiative-gradient helper in [Residual Assembly](../methods/residual-assembly.md) and contributes density and temperature sensitivities in [Jacobian Construction](../methods/jacobian-construction.md). In other words, opacity influences both the transport residual itself and the local linearization that Newton uses.

For a student, the conceptual chain is:

1. microphysics supplies $\kappa(\rho,T,X,Y,Z)$,
2. transport uses that $\kappa$ to build `nabla_rad`,
3. the Jacobian uses `dκ/dT` and `dκ/drho` to linearize how `nabla_rad` changes when the state changes.

## What a richer opacity ecosystem would add later

Analytical opacity is only the first rung of the ladder. A broader stellar-physics ecosystem usually adds:

- Rosseland-mean opacity tables,
- low-temperature molecular and grain-opacity tables,
- conductive opacity,
- table blending across regime boundaries,
- composition-aware opacity interpolation,
- validation data products and regime maps.

The local Stellax physics tree already contains table loaders, composition-aware opacity objects, conductive-opacity support, and blend machinery. ASTRA should eventually grow in that direction. For now, this page should teach the analytical closure ASTRA actually uses.

## What is deferred

Real opacity tables, conductive opacity, and table-blend hierarchies are deferred. The H-minus term is a simplified analytical proxy, not a production low-temperature opacity table, and the electron-scattering term is still an analytical correction rather than a full transport-opacity treatment. The current page should be read as the exact staged closure used today, not as a promise about ASTRA's eventual opacity stack.

## Internal QA

### Implementation checklist

- [x] The active analytical opacity is stated as the sum of Kramers, H-minus, and electron-scattering terms.
- [x] The page explains the physical regime each term is meant to represent.
- [x] The page states clearly that ASTRA uses explicit local finite differences for `dκ/dT` and `dκ/drho`.
- [x] The page links opacity ownership to the transport helper and Jacobian path.

### Testing checklist

- [x] ASTRA has direct analytical opacity regression tests for component behavior.
- [x] ASTRA has local derivative validation for the opacity sensitivities used in transport checks.
- [x] ASTRA has transport-row tests that exercise opacity-dependent behavior through the structure equations.
- [ ] A student-facing opacity-regime plot or worked example is still missing.

### Validation checklist

- [ ] The staged analytical opacity closure is benchmarked against a known analytic expectation or trusted reference over a representative state range.
- [ ] The regime boundaries for the H-minus window should eventually be validated against a better low-temperature reference.
- [ ] Production-grade opacity claims remain deferred until real table or blend validation artifacts exist.

### Deferred-scope checklist

- [x] Real Rosseland tables are not yet part of the active ASTRA opacity lane.
- [x] Conductive opacity is not yet part of the active ASTRA opacity lane.
- [x] Composition-aware opacity blending is deferred.
- [x] The present H-minus treatment is intentionally a staged proxy, not a final atmosphere-grade opacity model.
