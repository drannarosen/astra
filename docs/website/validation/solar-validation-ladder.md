# Solar Validation Ladder

ASTRA's first solar benchmark should be treated as a **validation ladder**, not a single pass/fail number at solar age.

This matters because a code can sometimes match one present-day observable for the wrong structural reasons. ASTRA should only trust the solar lane if the path to the result is physically interpretable as well.

Use this page as a reminder that "solar success" is not one number. It is a chain of increasingly stronger claims, and each tier changes what ASTRA is allowed to say with a straight face.

## Tier 0: Structural sanity

These checks must pass before ASTRA is allowed to claim even a provisional hydrostatic model:

- positive density and temperature,
- monotone enclosed mass and radius,
- EOS closure sanity,
- finite residuals and Jacobians,
- stable state packing and unpacking.

## Tier 1: Relaxation acceptance

The seed model is not automatically an accepted physical starting model.

Relaxation acceptance should use a mixed criterion:

- residual closure,
- physical admissibility,
- and stable end-of-relaxation behavior.

The model should not proceed to true evolution until ASTRA can justify that handoff.

## Tier 2: PMS evolution acceptance

The code should then demonstrate a physically interpretable PMS contraction lane:

- quasi-static contraction behavior,
- explicit gravothermal bookkeeping,
- sensible timestep control,
- and no pathological solver behavior.

At this stage ASTRA should not yet claim "solar validation." It should claim only that the PMS lane is behaving plausibly.

## Tier 3: ZAMS detection

ASTRA should define ZAMS primarily through energy partition:

- nuclear support dominates over gravothermal support,
- the condition persists over a declared number of accepted steps,
- and supporting diagnostics such as central hydrogen and central temperature are recorded.

This is deliberately similar in spirit to MESA's operational `Lnuc/L` near-ZAMS criterion, though ASTRA should expose the underlying energy bookkeeping clearly in its own diagnostics. See [MESA running guide](https://docs.mesastar.org/en/release-r22.05.1/using_mesa/running.html) and [MESA make_zams](https://docs.mesastar.org/en/stable/test_suite/make_zams.html).

## Tier 4: Solar-age target vector

The first compact ASTRA solar target vector should be:

- luminosity `L`,
- radius `R`,
- effective temperature `T_eff`,
- surface `Z/X`,
- central hydrogen `X_c`.

This target vector is intentionally modest. It gives ASTRA a meaningful early benchmark without pretending that the code already has profile-level solar precision or helioseismic realism.

## What this ladder does not yet prove

Even if ASTRA reaches Tier 4, that does **not** yet prove:

- calibrated convection,
- profile-level solar agreement,
- precision abundance evolution,
- or high-mass initialization correctness.

Those require later validation layers and should not be smuggled into the meaning of the first solar milestone.
