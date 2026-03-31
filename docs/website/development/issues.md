# Issues

This page tracks known limitations and unresolved questions that should stay visible while ASTRA grows.

## Active issues

### Bohm-Vitense MLT is now implemented, but the global solve still needs basin work

The Bohm-Vitense MLT hard cutover is now in the active residual, and the
accepted `default-12` outer transport row is convective. That is the correct
physics owner change, but the live bundle still has `converged = false` and
`used_regularized_fallback = true`, so the next issue is no longer "does ASTRA
know the convective branch?" It is "what broader boundary or basin work is
still needed for the nonlinear solve to settle."

The new development note is `2026-03-31-bohm-vitense-mlt-hard-cutover`, and
the relevant measured fields are `accepted_transport_hotspot_location`,
`accepted_dominant_family`, `used_regularized_fallback`, and the outer-row
transport diagnostics.

### Outer transport pressure alignment helps numerically but does not change the owner

The new outer-transport pressure-coupling audit shows that aligning the outer
transport row to the selected surface-pressure target improves the
`default-12` merit materially, but it does not recover convergence and it does
not change the accepted outer-boundary owner away from `surface_pressure`.

The audit manifest now carries a literal `outer_transport_pressure_label`
field so the `photospheric_face` and `selected_pressure_target` payloads stay
easy to separate in later reviews. The dated audit note is
`2026-03-31-outer-transport-pressure-coupling-audit`, and the key headline
fields remain `accepted_transport_hotspot_location` and
`accepted_outer_boundary_dominant_family`.

what this does not prove:

### Pressure closure control still does not rescue convergence

The new pressure-closure control audit shows that switching the selected
pressure target from the bridge lane to `photosphere_control` changes the
numeric burden but does not recover convergence. Both lanes remain
bridge-dominated in the focused bundle, which means the current live surface
pressure owner is still the deeper bridge semantics rather than a
photospheric-pressure shortcut.

The audit manifest now carries a literal `pressure_closure_label` field so the
bridge and photosphere-control payloads stay easy to separate in later reviews.
The dated audit note is `2026-03-31-pressure-closure-control-audit`, and the
headline manifest field remains `accepted_surface_pressure_bridge_dominant`.

### Classical residual convergence basin is still provisional

ASTRA's default classical initializer now includes center asymptotic targets, solver-side luminosity conditioning, a Phase 2 one-sided `T(\tau)` atmosphere boundary, and a higher-fidelity structured Jacobian. The public 12-cell example now takes accepted Newton steps again and lowers the weighted residual to a small finite value, but it still does not converge cleanly enough to call the classical lane robust. The remaining blocker is now a mix of closure maturity and accepted-step quality rather than "can ASTRA move at all?"

### Surface closure is now staged, not finished

The current outer boundary uses a Phase 2 one-sided `T(\tau)` atmosphere closure; temperature is photospheric, while pressure and optical-depth helpers still reference the deeper matching concept, and the outer transport row remains one-sided to the photospheric face. That is better than the old provisional closure, but it is still not proven across a broader convergence basin.

That means the current boundary story still needs either a bridge reinterpretation or a more complete atmosphere/relaxation slice. The photospheric-pressure control lane is useful as a negative control, not as the canonical answer.

### Evolution remains intentionally stubbed

`step_evolution!` is contract-consistent with `StellarModel`, but there is still no accepted PMS or main-sequence evolution algorithm in code.

### Validation is still early-stage

The current test suite proves package integrity, ownership boundaries, example integrity, exact-row local derivative validation for the current toy helper kernels, the structured Jacobian audit surface, explicit solve-boundary diagnostics, and the staged atmosphere closure. It does not yet prove a trustworthy solar lane or a converged classical nonlinear solve.

## Questions to keep asking

- what should Phase 3 atmosphere comparison cover first after the Phase 2 helper-layer slice: explicit `T(\tau)` variants or tabulated atmosphere matching?
- what is the smallest accepted PMS seed-and-relaxation slice that gives a meaningful hydrostatic handoff and a better Newton starting model?
- when should ASTRA begin recording dated progress entries automatically from completed plans or merged slices?
