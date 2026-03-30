# Analytical Physics Completion Design

**Date:** 2026-03-29

**Goal:** Enrich ASTRA's analytical physics stack toward a more complete classical energy and thermodynamics model without widening the current public ownership contract.

## Decision

Keep ASTRA's current public ownership contract fixed in this slice:

- `MicrophysicsBundle` remains the public closure container.
- Closures remain callable in linear cgs variables `(density_g_cm3, temperature_k, composition)`.
- The public nuclear closure payload stays narrow and does not grow abundance time derivatives.
- The solve-owned state vector remains the current structure block.

Within that fixed contract, enrich the analytical physics in three lanes:

1. Add residual-owned analytical `eps_grav` and `eps_nu`.
2. Enrich the analytical nuclear closure with screening and optional triple-alpha.
3. Enrich the analytical EOS with analytical degeneracy and Coulomb corrections behind validation gates.

## Why This Approach

This is the best near-term path because it improves the physical completeness of ASTRA's analytical lane without destabilizing the current API, Jacobian basis, or solver ownership model. The alternative would be to widen the public contract before the analytical source and thermodynamic terms are validated, which would mix architectural change with physics change and make failures much harder to localize.

This approach also avoids the trap of silently treating `eps_grav = 0` as if it were an acceptable default. Instead, the design introduces an explicit internal owner for `eps_grav` tied to evolution-time bookkeeping, so the term exists as a real analytical quantity even before ASTRA has a fully exercised evolution lane.

## Architecture

### 1. Energy-Source Lane

The luminosity row should move from

$$
\frac{dL}{dm} = \varepsilon_\mathrm{nuc}
$$

to an explicit source-decomposed realization of

$$
\frac{dL}{dm} = \varepsilon_\mathrm{nuc} + \varepsilon_\mathrm{grav} - \varepsilon_\nu.
$$

The public microphysics closures do not need to widen for that to happen. Instead, the residual helper layer becomes the source owner that assembles:

- `eps_nuc` from the analytical nuclear closure,
- `eps_nu` from an analytical neutrino-loss helper,
- `eps_grav` from internal evolution-owned thermodynamic history.

`eps_grav` should not be faked from Newton iteration state or from a pseudo-time inside the static solve. The design choice is to make `eps_grav` evolution-owned, using a previous accepted model snapshot and timestep bookkeeping internal to ASTRA's state/evolution layer. That keeps the physics owner honest even if the current bootstrap lane only exercises it lightly at first.

### 2. Nuclear Lane

`AnalyticalNuclear` remains the public closure, but becomes internally richer:

- analytical PP and CNO stay active,
- screening becomes available,
- triple-alpha becomes available,
- the public payload still returns only the current energy-rate contract.

This keeps abundance evolution out of the public interface for now. Internally richer formulae are allowed, but no `dX/dt`, `dY/dt`, or composition-transport ownership should leak into the active ASTRA closure contract in this slice.

### 3. EOS Lane

`AnalyticalGasRadiationEOS` remains the EOS owner for pressure and thermodynamic response. The closure may gain analytical degeneracy and Coulomb corrections, but those are introduced under flags first and only move toward default-on after derivative validation and solver checks show the path is numerically safe.

This means:

- no entropy-authoritative inversion contract yet,
- no table-backed EOS,
- no public expansion of the payload beyond the current pressure and thermodynamic response fields ASTRA already consumes.

## Ownership Map

### Solver-owned

- structure variables in the packed Newton solve,
- luminosity-row source assembly,
- row/Jacobian basis conversion into packed solve variables.

### Evolution-owned internal state

- previous accepted thermodynamic state needed for `eps_grav`,
- timestep metadata needed to interpret time-centered gravothermal terms.

### Diagnostic-only or deferred

- abundance time derivatives,
- composition evolution,
- reaction-network ownership,
- entropy-authoritative inversion,
- table-backed EOS and opacity,
- real MLT and transport of composition.

## Default-On vs Flag-Gated Policy

### Default-on once validated

- analytical `eps_grav`,
- analytical `eps_nu`.

### Flag-gated first

- screening,
- triple-alpha,
- degeneracy corrections,
- Coulomb corrections.

This policy keeps the classical energy equation honest while forcing the riskier thermodynamic enrichments through targeted tests before they touch the default solve path.

## Validation Strategy

### Energy-source lane

- local source decomposition tests for `eps_nuc`, `eps_grav`, `eps_nu`,
- luminosity-row residual tests,
- luminosity-row Jacobian audits,
- center/surface sanity checks on sign and units.

### Nuclear lane

- local analytical tests for screened PP/CNO and optional triple-alpha,
- derivative agreement tests,
- block-Jacobian and Newton-progress checks if defaults change.

### EOS lane

- local EOS payload and derivative tests at center-like and envelope-like states,
- transport-helper sensitivity tests,
- solver/Jacobian checks before any default-on switch.

### Documentation and checklist lane

Every newly implemented analytical term must be paired with:

- an honest physics-page update,
- a checklist update naming whether the term is active, flag-gated, or deferred,
- a docs-structure test update so the handbook stays synchronized with the code.

## Relevant Documentation Surfaces

The implementation plan should include same-slice updates to:

- `docs/website/physics/eos.md`
- `docs/website/physics/eos/analytical-eos.md`
- `docs/website/physics/nuclear.md`
- `docs/website/physics/nuclear/analytical-burning.md`
- `docs/website/physics/stellar-structure/energy-generation.md`
- `docs/website/physics/stellar-structure/coupled-problem.md`
- `docs/website/numerics/residuals.md`
- `docs/website/methods/jacobian-construction.md`
- `docs/website/development/checklists/solar-first-lane.md`
- related docs-structure expectations in `test/test_docs_structure.jl`

## Deferred After This Design

This design explicitly does **not** widen the public ownership contract yet. The following remain follow-on contract questions:

- abundance-evolution payloads on the nuclear closure,
- composition transport in the evolution lane,
- entropy-authoritative EOS ownership,
- real table-backed EOS and opacity,
- production-grade reaction networks.
