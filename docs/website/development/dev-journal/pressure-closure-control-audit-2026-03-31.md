# Pressure Closure Control Audit 2026-03-31

Artifact bundle: `artifacts/validation/2026-03-31-pressure-closure-control-audit`

Retention status: `current`

This page records the focused control comparison between ASTRA's current
bridge pressure target and a photospheric-pressure control target. The control
lane is diagnostic only.

The literal `pressure_closure_label` in the manifest records which closure mode
generated each payload.
The phrase `photospheric-pressure control lane` is the intended shorthand for
the internal photosphere-control closure path.

## What was compared

- `bridge`: the current selected pressure target, which keeps the deeper
  `P_ph + g\sigma_{1/2}` match point.
- `photosphere_control`: an internal control lane that swaps the selected
  pressure target to the photospheric face while keeping the rest of the solve
  unchanged.

Both lanes use the same `bootstrap_default` seed family, the same `default-12`
base problem, and the same three `1.0e-6` perturbation cases.

## Measured result

The control lane changes the magnitude of the residuals, but it does not cure
the solve and it does not remove the bridge-dominated surface-pressure story.

Measured headline facts from the manifest:

- `bridge-default-12`: `converged = false`, `accepted_step_count = 8`,
  `rejected_trial_count = 801`, `initial_merit = 7.606095159786209`,
  `final_merit = 7.137553468301087`, `accepted_surface_pressure_bridge_dominant = true`
- `photosphere_control-default-12`: `converged = false`,
  `accepted_step_count = 6`, `rejected_trial_count = 1110`,
  `initial_merit = 929.4997975183256`, `final_merit = 414.1399030307972`,
  `accepted_surface_pressure_bridge_dominant = true`

The focused perturbation cases tell the same story:

- the control lane remains `converged = false`,
- the accepted dominant surface family stays `surface_pressure`,
- and the accepted outer-boundary dominant family stays `surface_pressure`.

## Interpretation

This is a useful negative control. It shows that changing the selected pressure
target alone does not make ASTRA converge, and it does not move the live
surface owner away from `surface_pressure`.

It also tells us something narrower and more valuable than a generic
"it still fails" statement: the pressure target selection influences the
numeric burden, but the current basin is still not owned by the photospheric
control lane.

## what this does not prove

- This does not prove that the bridge target is physically correct.
- This does not prove that the photospheric control lane is the right long-term
  boundary condition.
- This does not prove that pressure semantics are the only remaining issue.
- This does not prove robust convergence across broader model families.

## Next step

Keep the pressure control lane internal and diagnostic-only. The measured result
still points to the live surface-pressure bridge semantics as the near-term
owner, while the long-term architecture remains PMS-first with explicit
relaxation and evolution handoff.
