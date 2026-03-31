# Outer Boundary Fitting-Point Ownership Audit

This note records the interpretation of the focused `2026-03-30-outer-boundary-fitting-point-ownership-audit` bundle at `artifacts/validation/2026-03-30-outer-boundary-fitting-point-ownership-audit/`.

## Code-backed helper decomposition

ASTRA's current outer-boundary helpers are split into two distinct bridges:

- `outer_match_temperature_k(problem, model)` computes the one-sided outer-cell temperature match point from the Eddington `T(\tau)` reconstruction.
- `outer_match_pressure_dyn_cm2(problem, model)` computes the one-sided outer-cell pressure match point from the photospheric pressure scale plus the half-cell hydrostatic offset.
- `outer_boundary_fitting_point_terms(problem, model)` records both the current match-point values and the photospheric fitting-point values, together with `temperature_contract_log_gap` and `pressure_contract_log_gap`.

That decomposition is important because it shows the temperature bridge and the pressure bridge are not the same owner, even though they are reported together in the same outer-boundary summary.

## Measured bundle

The focused bundle keeps the accepted transport hotspot on the outer row at cell index `11` in every payload, but the surface-family story splits. Every payload in the focused bundle is still `converged = false` and `used_regularized_fallback = true`.

| case | accepted dominant surface family | accepted `temperature_contract_log_gap` | accepted `pressure_contract_log_gap` | best-rejected `temperature_contract_log_gap` | best-rejected `pressure_contract_log_gap` |
| --- | --- | ---: | ---: | ---: | ---: |
| `default-12` | `surface_pressure` | `-2.599766419592937` | `0.0` | `-2.5065361725953963` | `0.0` |
| `perturb-a1e-6-case-01` | `surface_temperature` | `-2.042813446857039` | `0.0` | `-1.9537579593619334` | `0.0` |
| `perturb-a1e-6-case-02` | `surface_pressure` | `-4.162187353515018` | `0.0` | `-1.9538156698440865` | `0.0` |
| `perturb-a1e-6-case-03` | `surface_temperature` | `1.1417404995256852` | `0.0` | `0.0805409907507979` | `0.0` |

The pressure bridge is code-identical: both sides build the same `P_ph + g σ_half` bridge, so `pressure_contract_log_gap = 0.0` deprioritizes pressure-bridge-gap ownership but does not independently validate pressure semantics.

The temperature bridge is not cleanly tracking the same way: the accepted gap stays negative in `default-12`, case `01`, and case `02`, but flips positive in case `03`.

## Interpretation

Stop-rule outcome: outer-boundary failure remains mixed, with pressure bridge ownership deprioritized and temperature bridge mismatch the sharper remaining non-pressure candidate.

That is the most conservative reading that still respects the evidence:

- the pressure bridge is code-identical in this bundle rather than independently validated,
- the temperature bridge remains a real mismatch and does not stay sign-stable across perturbations,
- and the accepted dominant surface family splits between `surface_pressure` and `surface_temperature`.

## what this does not prove

- This does not prove a solver rewrite is needed.
- This does not prove the outer boundary is the only bottleneck.
- This does not prove the temperature bridge alone explains the surface behavior.
- This does not prove parity with any external atmosphere implementation.
