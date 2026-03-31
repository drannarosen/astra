# Bohm-Vitense MLT Hard Cutover, 2026-03-31

Artifact bundle: `artifacts/validation/2026-03-31-bohm-vitense-mlt-hard-cutover`

This note records the first ASTRA slice where the active transport residual
stops pretending convection is only a label. The branch-owned transport owner
is now Bohm-Vitense local MLT, and the accepted outer transport row in the
default validation bundle is genuinely convective.

## Code-backed fact

- `BohmVitenseMLTConvection(1.8)` is the default convection owner.
- `cell_transport_state(...)` builds a numerics-owned local convection state
  and returns a typed transport state.
- `transport_row_terms(...)` reads the branch-owned `active_gradient` instead
  of the radiative candidate.
- The diagnostics layer reports the same branch-owned transport state that the
  residual consumes.

## Measured result

The live `default-12` bundle still does not converge, but the accepted outer
transport row is now convective and the solver is no longer solving the row as
if radiation alone owned it.

- `initial_merit = 7.365057367071724`
- `final_merit = 6.80399934664248`
- `accepted_dominant_family = surface`
- `accepted_transport_hotspot_location = outer`
- `used_regularized_fallback = true`
- `transport_regime = convective`
- `transport_guarded = false`
- `nabla_radiative = 37.387981274479316`
- `nabla_ledoux = 0.3998977412791282`
- `nabla_transport = 0.3998977412791282`
- `superadiabatic_excess = 0.0`
- `convective_velocity_cm_s = 2034.6002870572959`
- `convective_flux_fraction = 0.9893041098329614`

## Interpretation

The wrong-branch transport owner was a real part of the remaining burden: the
accepted outer row is now physically convective, and the diagnostics show a
large convective flux fraction instead of a radiative-only answer.

What this does not mean is that the whole solve is healthy. The bundle still
does not converge, fallback is still used, and the dominant family remains the
surface boundary. So this cutover fixes the transport owner, but it does not by
itself solve the broader nonlinear basin problem.

The scientifically important distinction is now clear:

- code-backed fact: transport rows use the branch-owned active gradient,
- measured result: the accepted outer row is convective, but the bundle still
  fails to converge,
- interpretation: wrong-branch transport mattered, but it was only one part of
  the remaining burden.
