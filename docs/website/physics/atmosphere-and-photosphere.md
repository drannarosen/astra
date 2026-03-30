# Atmosphere and Photosphere

The stellar atmosphere is the thin outer layer that connects a star's interior to the region where the optical depth becomes small. The photosphere is the conventional surface marker in that atmosphere. In a grey approximation, the photosphere is often defined near optical depth

$$
\tau = \frac{2}{3}.
$$

That choice is not arbitrary. It is the standard Eddington-grey reference point where the atmosphere is thin enough that a single surface match is a useful first approximation, but still deep enough that the outer layer is not yet free space.

This page is ASTRA's canonical atmosphere reference for the classical lane. It explains what the photosphere means, what the current Eddington-grey closure does, and which atmosphere phases are staged for later work.

## Why atmospheres matter

The interior structure equations do not stop caring about physics at the outer face. They need a boundary prescription that says how the interior connects to the observable surface. That boundary prescription controls the outer temperature, pressure, and transport behavior, and it often determines whether the global solve converges in a physically meaningful basin.

The photosphere is the simplest place to anchor that connection. It gives us a temperature scale through the effective temperature and a pressure scale through optical depth and gravity. A full atmosphere model can do more, but even the simplest photospheric match is much better than guessing a surface density and hoping the outer transport row will recover the rest.

## Eddington-grey closure

For a grey atmosphere, the effective temperature is defined by the Stefan-Boltzmann relation

$$
T_\mathrm{eff} = \left(\frac{L}{4 \pi \sigma R^2}\right)^{1/4},
$$

where `L` is the surface luminosity, `R` is the surface radius, and `\sigma` is the Stefan-Boltzmann constant.

The associated photospheric pressure scale uses the surface gravity and opacity:

$$
g_\mathrm{surf} = \frac{G M}{R^2},
$$

$$
P_\mathrm{ph} \approx \frac{2}{3}\frac{g_\mathrm{surf}}{\kappa_\mathrm{surf}}.
$$

Here `\kappa_\mathrm{surf}` is the local Rosseland-mean opacity at the outer cell. ASTRA's current atmosphere closure uses this pressure scale as a representative photospheric target, not as a full atmosphere integration.

## Current ASTRA implementation

ASTRA's current Phase 1 atmosphere implementation keeps the existing outer radius and luminosity target rows, but replaces the provisional outer thermodynamic guesses with atmosphere-derived targets:

- the outer cell temperature is matched in log form to `T_eff`,
- the outer cell pressure is matched against `P_ph`,
- the final transport row is one-sided and uses the photospheric target instead of an interior-style generic stencil.

This is a representative-cell approximation. It treats the outermost cell as the photospheric stand-in for now. That is scientifically stronger than a fixed surface-density guess, but it is still a bootstrap approximation rather than a final atmosphere module.

Why this is a reasonable first slice:

- it preserves ASTRA's current public structure-state contract,
- it keeps luminosity linear in cgs `erg/s`,
- it gives the outer boundary a physically interpretable temperature and pressure,
- and it sets up a clean later upgrade to a real `T(\tau)` relation.

## Planned phases

### Phase 1: Eddington-grey representative-cell closure

Status: implemented.

- keep outer radius and luminosity target rows,
- set the surface temperature target through `T_eff`,
- set the surface pressure target through `P_ph`,
- treat the outermost cell as the photospheric representative cell,
- make the last transport row one-sided and atmosphere-aware.

### Phase 2: explicit `T(\tau)` photosphere match

Planned next.

- add a more explicit optical-depth-based surface reconstruction,
- use a one-sided `T(\tau)` relation instead of identifying the outer cell with the photosphere,
- keep the same public solve contract if possible.

### Phase 3: richer atmosphere options

Deferred.

- support alternative `T(\tau)` relations,
- potentially support tabulated atmosphere surfaces,
- decide whether ASTRA should own more explicit atmosphere state or keep a compact closure layer.

## What this page is not

This is not a claim that ASTRA already has a production atmosphere module.
This is not a claim that the outer boundary is finished.
This is not a claim that the photosphere is a fully resolved transport layer.

The current implementation is intentionally staged and explicit about that staging.

## Atmosphere roadmap checklist

- [x] The photosphere is defined in the Eddington-grey sense as a `tau = 2/3` reference layer.
- [x] The effective temperature relation `T_eff = (L / (4 pi sigma R^2))^(1/4)` is written explicitly.
- [x] The photospheric pressure estimate `P_ph ~ (2/3) g / kappa` is written explicitly.
- [x] ASTRA's current Phase 1 representative-cell implementation is described honestly.
- [x] The Phase 2 `T(\tau)` upgrade path is named explicitly.
- [x] The Phase 3 richer-atmosphere path is named explicitly.
- [x] The page distinguishes current implementation from planned atmosphere work.
- [ ] Add a source-backed `T(\tau)` comparison note once Phase 2 lands.
- [ ] Add a benchmark artifact showing how the atmosphere closure changes the classical convergence basin.
