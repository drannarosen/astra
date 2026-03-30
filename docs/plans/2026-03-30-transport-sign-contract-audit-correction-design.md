# Transport Sign-Contract Audit And Correction Design

## Goal

Resolve whether ASTRA's current transport row uses a sign convention that is inconsistent with the documented meaning of `nabla`, and if so, correct the smallest canonical owner before any further transport hardening.

## Current evidence

### Code-backed facts

- ASTRA documents

  $$
  \nabla \equiv \frac{d \log T}{d \log P}
  $$

  in `docs/website/physics/stellar-structure/energy-transport.md`.

- ASTRA currently documents and implements the transport row as

  $$
  R_{T,k} = \log T_{k+1} - \log T_k + \nabla_k \left(\log P_{k+1} - \log P_k\right)
  $$

  in `docs/website/methods/residual-assembly.md` and `src/numerics/residuals.jl`.

- The current canonical transport decomposition helper in `src/numerics/structure_equations.jl` now records transport rows as:
  - `delta_log_temperature`
  - `delta_log_pressure`
  - `nabla_transport`
  - `gradient_term = nabla_transport * delta_log_pressure`
  - `residual = delta_log_temperature + gradient_term`

### Measured hotspot evidence

The refreshed artifact bundle `artifacts/validation/2026-03-30-transport-hotspot-diagnostics/` shows:

- `default-12` accepted hotspot:
  - `location = interior`
  - `cell_index = 10`
  - `delta_log_temperature = -0.7075755838009616`
  - `delta_log_pressure = -0.7082023843532852`
  - `nabla_transport = 0.42493962946976493`
  - `gradient_term = -0.30094325879668904`
  - `raw_residual = -1.0085188425976508`

- The current stalled hotspot is therefore large because both transport terms are negative and reinforce.

- The helper derivative audit on the solved `default-12` state showed the transport helper sensitivities matching finite differences essentially to machine precision across the transport family, so the current sharp blocker is not helper derivative correctness.

## Interpretation

If ASTRA means `nabla = d log(T) / d log(P)` in the standard sense, then for an outward step with:

- `delta_log_pressure < 0`
- `nabla > 0`

the physically consistent temperature drop should satisfy:

$$
\Delta \log T = \nabla \, \Delta \log P,
$$

which is also negative.

But the current residual reaches zero only if:

$$
\Delta \log T = - \nabla \, \Delta \log P,
$$

which is positive when `delta_log_pressure < 0`.

That is why the current row appears to ask for outward temperature increase at zero residual, despite the docs saying temperature should fall outward.

## Decision

Treat this as a likely structural sign-contract mismatch, not as a conditioning-first problem.

The next slice should:

1. write red tests that pin the transport sign semantics directly,
2. carry a candidate correction in the same slice,
3. only allow that correction to land if the tests confirm the mismatch,
4. refresh the hotspot artifact bundle afterward so the new diagnosis is based on the corrected contract.

## Candidate correction

The default candidate correction is:

- current: `delta_log_temperature + nabla_transport * delta_log_pressure`
- candidate: `delta_log_temperature - nabla_transport * delta_log_pressure`

for both:

- the interior transport row,
- and the one-sided outer transport row.

If the audit reveals that ASTRA is intentionally using an opposite sign convention for `nabla` everywhere, then the slice should stop and correct the documentation instead of the residual.

## Scope

### In scope

- transport-row sign-contract tests
- canonical transport decomposition helper update if the tests confirm mismatch
- dependent residual and hotspot diagnostics updates
- docs updates in the same slice
- refreshed validation artifacts

### Out of scope

- adaptive regularization
- trust-region logic
- new atmosphere-provider interfaces
- convection model changes
- solve-basis changes
- broad conditioning redesign

## Success criteria

- transport row, transport helper, and docs use one internally consistent sign convention
- the row no longer implies outward temperature increase when `delta_log_pressure < 0`
- hotspot diagnostics still run and now reflect the corrected contract
- the refreshed artifact bundle tells us whether the near-surface interior hotspot survives the sign correction

## Falsifiers

The slice should stop and explain rather than force a correction if:

- ASTRA already uses the opposite `nabla` sign convention consistently in code and docs, and the present issue is only a localized documentation mismatch
- or the new red tests show that the candidate correction breaks a physically intended convention elsewhere in the current lane

## Expected next decision

After the sign-contract slice lands, ASTRA should be able to answer a sharper question:

- is the near-surface interior transport hotspot still the dominant failure signal under a physically consistent transport sign convention?

If yes, the next hardening slice should target the surface-adjacent interior transport stencil and its interface to the surface closure. If no, the hotspot evidence may shift enough to change the next target.
