# Solar-First Strategy

ASTRA's first serious science program is **not** "all stars at once." It is a single, trustworthy lane:

- single-star,
- 1D,
- hydrostatic,
- solar-mass,
- solar-composition baseline,
- evolved from the pre-main sequence through ZAMS and onto the main sequence.

This page records the strategy approved during the March 29, 2026 design discussions.

Read this page as a scope-discipline document. Its job is to keep ASTRA focused on one scientifically interpretable flagship lane long enough for validation to mean something.

## Why a solar-first lane

The Sun is not just convenient. It is the right first scientific stress test for ASTRA because it forces the code to connect:

- structure,
- energy bookkeeping,
- convection,
- composition evolution,
- and validation against a compact, physically interpretable target.

That is ambitious enough to matter scientifically, but still narrow enough to keep ASTRA from drifting into feature-sprawl before the baseline methods are trustworthy.

## The initialization pipeline

ASTRA's first validated solar lane should follow this explicit workflow:

1. build a low-mass PMS seed,
2. relax the seed by pseudo-evolution into an accepted hydrostatic starting model,
3. evolve through PMS contraction,
4. detect ZAMS using an energy-partition criterion,
5. continue main-sequence evolution to solar age.

Each of those stages should have its own acceptance logic. Seed construction, relaxation, and true evolution must remain distinct ideas in the architecture and in the diagnostics.

## Seed-builder policy

The seed-builder framework should be general enough to host more than one family, even though ASTRA will validate only the low-mass path first.

### Implement first

- `convective_pms_seed`

This first lane should be:

- low-mass focused,
- near-adiabatic in spirit,
- contraction-powered rather than fusion-powered,
- simple enough to debug and relax reliably.

### Reserve now, implement later

- `higher_mass_pms_seed`
- or a more explicitly protostellar / birthline-aware seed family

ASTRA should not pretend that the same low-mass PMS seed is structurally correct for all stellar masses.

## Relaxation policy

Relaxation is a real algorithmic stage, not a side-effect of the first evolution steps.

The approved contract is:

- composition fixed during relaxation,
- pseudo-evolution controls such as damping or continuation are allowed,
- the endpoint is an **accepted hydrostatic starting model**,
- handoff to evolution happens only after mixed acceptance criteria are satisfied.

## ZAMS policy

ASTRA should define ZAMS primarily through **energy partition**, not through a single temperature or composition threshold.

The approved concept is:

- the star approaches ZAMS when nuclear support overtakes gravothermal support,
- the criterion should be persistent over multiple accepted steps,
- composition and central temperature remain important supporting diagnostics but are not the primary definition.

This is intentionally close in spirit to MESA's use of `Lnuc/L` as a practical near-ZAMS criterion. See the official MESA docs for the `make_zams` test and `Lnuc_div_L_zams_limit`: [MESA make_zams](https://docs.mesastar.org/en/stable/test_suite/make_zams.html), [MESA controls defaults](https://docs.mesastar.org/en/25.12.1/reference/controls.html#lnuc-div-l-upper-limit).

## Convection policy

ASTRA should include a **real MLT-based convection closure** in the first classical baseline lane.

Convection is not a stretch-goal for the solar problem. It influences the radius, luminosity, and effective temperature strongly enough that a solar-facing baseline without convection would be scientifically misleading.

Approved baseline policy:

- one explicit MLT-like closure,
- fixed declared `alpha_MLT`,
- no calibration machinery in the first milestone.

Later comparison work can add:

- alternative effective-transport closures,
- calibration workflows,
- and more experimental convection ideas.

## Scope-discipline rule

ASTRA should follow a strict anti-scope-creep rule:

> No new physics layer enters the baseline lane until its ownership, validation target, and handoff criteria are written down first.

That rule is especially important because the scientific ambition of ASTRA is broad. The code should grow by validated slices, not by accumulating partially trusted physics.
