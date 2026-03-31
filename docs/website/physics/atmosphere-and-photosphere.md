# Atmosphere and Photosphere

The stellar atmosphere is the thin outer layer that connects a star's interior to the region where the optical depth becomes small. The photosphere is the conventional surface marker in that atmosphere. In a grey approximation, the photosphere is often defined near optical depth

$$
\tau = \frac{2}{3}.
$$

That choice is not arbitrary. It is the standard Eddington-grey reference point where the atmosphere is thin enough that a single surface match is a useful first approximation, but still deep enough that the outer layer is not yet free space.

This page is ASTRA's canonical atmosphere reference for the classical lane. It explains what the photosphere means, what the current one-sided Eddington `T(\tau)` closure does, and which atmosphere phases are staged for later work.

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

Here `\kappa_\mathrm{surf}` is the local Rosseland-mean opacity at the outer cell. ASTRA's current atmosphere closure uses this pressure scale as the match-point target for the one-sided outer reconstruction, not as a full atmosphere integration.

## Current ASTRA implementation

ASTRA's current Phase 2 atmosphere implementation keeps the existing outer radius and luminosity target rows; the surface thermodynamic rows use the shared outer match-point helper layer, and the outer transport row remains one-sided to the photospheric face:

- the outer cell temperature is matched in log form to `outer_match_temperature_k(...)`,
- the outer cell pressure is matched in log form to `outer_match_pressure_dyn_cm2(...)`,
- the surface pressure row uses the shared outer match-point pressure contract in log form,
- the outer transport row remains one-sided to the photospheric face and uses `surface_effective_temperature_k(...)` plus `eddington_photospheric_pressure_dyn_cm2(...)`.

This is a one-sided `T(\tau)` reconstruction. It keeps the outer face as the photospheric reference while treating the outermost cell as a deeper match point instead of the photosphere itself.

Why this is a reasonable slice:

- it preserves ASTRA's current public structure-state contract,
- it keeps luminosity linear in cgs `erg/s`,
- it gives the outer boundary a physically interpretable match-point temperature and pressure,
- and it keeps the solver-side transport and pressure weighting on the same atmosphere semantics as the residual rows.

## Phase roadmap

### Phase 2: explicit `T(\tau)` photosphere match

Status: implemented.

- preserve the current outer `R` and `L` target rows in this slice,
- keep the same public solve contract and packed basis `[\ln R, L, \ln T, \ln \rho]`,
- treat the outer face as the photosphere at `tau = 2/3`,
- reconstruct the outermost thermodynamic cell from a half-cell optical-depth estimate and hydrostatic column estimate.
- the surface thermodynamic rows use the shared outer match-point helper layer,
- route the surface pressure row through the shared outer match-point pressure contract in log form,
- keep the outer transport row one-sided to the photospheric face.

This design choice is deliberate. Phase 2 hardens atmosphere physics without simultaneously redesigning ASTRA's larger global model-family ownership. ASTRA may later revisit whether luminosity or radius should become emergent rather than targeted, but that is a separate project from the current atmosphere implementation.

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

## Current design choice for the next slice

The current approved atmosphere slice is:

- keep the current outer radius target row,
- keep the current outer luminosity target row,
- the surface thermodynamic rows use the shared outer match-point helper layer,
- keep the surface pressure scale aligned with the shared outer match-point pressure scale,
- keep the outer transport row one-sided to the photospheric face,
- keep richer atmosphere options and global-closure redesign out of scope for this implementation.

The reasoning is simple. ASTRA's current outer `R` and `L` rows still define the present bootstrap family, so changing them now would mix atmosphere hardening with a larger closure redesign. The better move is to keep the current ownership while making the atmosphere semantics and solver metrics consistent.

## Atmosphere roadmap checklist

- [x] The photosphere is defined in the Eddington-grey sense as a `tau = 2/3` reference layer.
- [x] The effective temperature relation `T_eff = (L / (4 pi sigma R^2))^(1/4)` is written explicitly.
- [x] The photospheric pressure estimate `P_ph ~ (2/3) g / kappa` is written explicitly.
- [x] ASTRA's current Phase 2 one-sided `T(\tau)` implementation is described honestly.
- [x] The Phase 2 `T(\tau)` upgrade path is recorded as implemented.
- [x] The Phase 3 richer-atmosphere path is named explicitly.
- [x] The page distinguishes current implementation from planned atmosphere work.
- [x] The approved Phase 2 choice to preserve outer `R` and `L` in that slice is recorded explicitly.
- [x] The shared outer match-point helper layer for the surface thermodynamic rows is recorded explicitly.
- [x] The solver-side surface-pressure row is matched in log form to the same match-point helper layer.
- [ ] Add a source-backed `T(\tau)` comparison note for the implemented Phase 2 closure.
- [ ] Add a benchmark artifact showing how the atmosphere closure changes the classical convergence basin.
