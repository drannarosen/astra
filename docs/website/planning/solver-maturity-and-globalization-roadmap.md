# Solver Maturity and Globalization Roadmap

This page is ASTRA's future-facing solver strategy note. It is not the canonical specification for the current nonlinear controller. The current implemented controller lives in [Methods: Nonlinear Step Metrics and Globalization](../methods/nonlinear-step-metrics-and-globalization.md). This page answers a different question:

> What kind of nonlinear-solver architecture should ASTRA grow into if the long-term goal is to evolve stars across all phases without turning the solver into an opaque beast?

That question matters because "future-proof" and "MESA-like" are not the same thing.

## The short answer

ASTRA should aim for a **merit-based globalization backbone** with explicit row-family diagnostics.

That does **not** mean ASTRA should stay permanently simple.

It means ASTRA should grow future solver complexity around one explicit organizing principle,

$$
\phi(x) = \frac{1}{2}\|W_r R(x)\|_2^2,
$$

rather than around an increasingly large collection of interacting acceptance heuristics.

In plain language:

- MESA's controller is more mature and more battle-tested today,
- ASTRA's best long-term architecture is still likely a merit-function backbone,
- and ASTRA will probably need additional solver machinery later, but that machinery should grow from the merit backbone instead of replacing it.

## Where ASTRA stands now

ASTRA's current classical lane already has several important ingredients:

- an explicit packed solve basis `[\ln R, L, \ln T, \ln \rho]`,
- solver-side row weights,
- solver-side correction weights,
- weighted correction limiting,
- one-sided atmosphere boundary semantics,
- and Jacobian validation discipline.

That is enough to make the current controller scientifically legible. It is not yet enough to call ASTRA's globalization strategy mature.

The current controller still works as a weighted damped Newton method with fallback regularization and explicit correction limiting. That is a good intermediate stage, but it still answers acceptance questions through a small ecology of rules instead of through one declared objective.

## Why not just copy MESA's controller?

The local MESA source shows a controller that is much richer than ASTRA's current one:

- explicit `x_scale`,
- explicit `residual_weight`,
- explicit `correction_weight`,
- correction norms and max-correction limits,
- domain-aware correction repair,
- multiple retry paths and controller adjustments.

Those patterns are visible in:

- `/Users/anna/projects/jaxstro-dev/legacy/stellax-legacy/reference/mesa/star/private/solver_support.f90`
- `/Users/anna/projects/jaxstro-dev/legacy/stellax-legacy/reference/mesa/star/private/star_solver.f90`

That machinery exists for good reasons. MESA must survive a vast range of stellar phases, physics options, and historical compatibility constraints.

So the right conclusion is **not** that MESA is overbuilt or wrong.

The right conclusion is:

- MESA's controller is more mature today,
- but ASTRA should be careful not to inherit MESA-scale controller complexity before ASTRA has made its own nonlinear objective explicit.

That distinction matters. A young code can accidentally become a mini-MESA controller long before it has earned the scientific clarity or numerical coverage that makes such complexity worthwhile.

## Why a merit-function backbone is attractive

The central attraction of a merit function is not that it makes the solver magically stronger. The attraction is that it gives the solver one explicit thing it is trying to reduce.

### One declared objective

If the solver defines

$$
\phi(x) = \frac{1}{2}\|W_r R(x)\|_2^2,
$$

then globalization decisions can be phrased in one consistent language:

- how much decrease did the linearized model predict,
- how much decrease actually happened,
- was the step good enough to accept,
- and did regularization or damping improve the merit behavior?

That is cleaner than saying:

- the weighted residual improved,
- the raw residual did not get worse,
- the correction was not too large,
- and the fallback path did not trigger anything pathological.

Those safeguards may still exist, but they stop being the primary language of the controller.

### Better diagnostics

A merit function also makes it much easier to explain failure.

Without it, ASTRA can say:

- the weighted norm went down or did not go down,
- the raw residual did or did not increase,
- a damping factor was or was not accepted.

With it, ASTRA can also say:

- the model predicted a decrease `\Delta \phi_\mathrm{pred}`,
- the nonlinear residual produced an actual decrease `\Delta \phi_\mathrm{act}`,
- the ratio `\rho = \Delta \phi_\mathrm{act} / \Delta \phi_\mathrm{pred}` was good, mediocre, or poor,
- and the dominant row families inside `\phi` were surface, hydrostatic, transport, luminosity, or center rows.

That is the difference between "the solver struggled" and "the solver rejected this step because the linear model overpredicted improvement in the outer transport rows."

### Better long-term extensibility

A merit-function controller is also a better bridge to later solver machinery:

- Armijo or Wolfe line search,
- trust-region logic,
- adaptive regularization,
- block-structured Newton-Krylov methods,
- formulation comparisons with a shared globalization objective.

Without a merit function, those later methods still need some acceptance target, so the code tends to accumulate controller folklore. With a merit function, the globalization layer already has a declared mathematical center.

## Does this still scale to full stellar evolution?

Yes, in principle absolutely.

But the honest answer is more precise than that:

- a merit-based controller is a **good foundation** for a full-evolution ASTRA,
- it is **not** the only solver machinery ASTRA will eventually need.

If ASTRA eventually handles:

- pre-main-sequence contraction,
- main-sequence hydrogen burning,
- shell burning,
- red giant envelopes,
- highly degenerate cores,
- stiff thermal and nuclear transients,
- and later formulation experiments,

then the solver will probably still need more than the first merit slice. Over time ASTRA may need:

- stronger predicted-versus-actual decrease logic,
- trust-region or Levenberg-style regularization policies,
- more domain-aware rejection and repair logic,
- better regime-aware scaling,
- timestep-aware continuation strategies,
- and richer failure classification.

The key design claim is therefore not:

> a merit function keeps ASTRA permanently small.

The key design claim is:

> a merit function gives ASTRA a clean backbone on which necessary complexity can later grow deliberately.

That is the future-forward point.

## Why row-family diagnostics matter just as much

Merit globalization alone is not enough.

A single scalar objective is useful for control, but stellar-structure debugging still needs structure. ASTRA's residual is not one monolithic thing. It is a collection of physically different row families:

- center rows,
- geometry rows,
- hydrostatic rows,
- luminosity rows,
- transport rows,
- surface rows.

A mature ASTRA controller should therefore report not only global merit numbers, but also row-family attribution:

- which family dominates the weighted objective,
- which family improved after an accepted step,
- which family blocked acceptance,
- and whether a regression came from the boundary, the transport equation, the center closure, or somewhere else.

That is important scientifically and architecturally.

Scientifically, it tells us which physics or boundary slice is actually failing.

Architecturally, it prevents the solver from becoming a black box where every failure looks like "the residual was large."

## What maturity would these next slices buy?

If ASTRA lands:

- a merit-function globalization controller,
- predicted-versus-actual decrease diagnostics,
- and row-family grouped diagnostics,

then ASTRA will still **not** be a production stellar evolution code.

But it will become something much more important than a promising prototype:

> a robust classical baseline with interpretable nonlinear solver behavior.

That would mean:

- the classical solve has a declared nonlinear objective,
- solver failure is attributable rather than mysterious,
- future physics slices can be judged against a clearer controller contract,
- and later complexity can be added from a stable base instead of from numerical folklore.

That is a real maturity threshold.

## What it still would not mean

Even after those slices land, ASTRA would still not yet imply:

- production microphysics,
- solar calibration,
- validated all-phase stellar evolution,
- mature timestep control,
- or final global closure design.

Those are later achievements.

The point is not to confuse "solver maturity" with "full stellar evolution maturity." The point is that a trustworthy solver backbone is a prerequisite for all the later ambitions.

## Recommended long-term growth path

The current recommended order is:

1. finish the merit-function globalization slice on the current classical lane,
2. add row-family diagnostics and validation artifacts,
3. strengthen controller diagnostics with predicted-versus-actual decrease accounting,
4. revisit trust-region or adaptive regularization behavior if merit diagnostics show that damping alone is insufficient,
5. expand physics and closure realism only after the controller remains interpretable under those changes,
6. revisit larger global-closure questions such as whether outer `L` and later outer `R` should remain targeted.

This sequence is deliberate. It says:

- first make the solver understandable,
- then make it broader.

## Design commitments for future ASTRA work

These are the future-facing rules implied by the current direction:

- ASTRA should prefer one explicit globalization objective over a growing bag of acceptance heuristics.
- ASTRA should remain source-backed when borrowing ideas from MESA.
- ASTRA should add complexity only when the simpler merit-based contract becomes the real bottleneck.
- ASTRA should expose row-family attribution before claiming solver robustness.
- ASTRA should treat controller diagnostics as part of the scientific architecture, not as debug-only output.
- ASTRA should resist importing production-code complexity before the classical lane has earned it.

## Planning checklist

- [x] The page states clearly that MESA is more battle-tested today.
- [x] The page states clearly that ASTRA still prefers a merit-function backbone.
- [x] The page explains why "cleaner" does not mean "simple forever."
- [x] The page explains that a full-evolution ASTRA will likely still need additional solver machinery later.
- [x] The page explains why row-family diagnostics are part of solver maturity, not optional reporting polish.
- [x] The page names the maturity threshold these slices would buy: a robust classical baseline with interpretable nonlinear solver behavior.
- [x] The page distinguishes solver maturity from full stellar-evolution maturity.
- [x] The page records a future growth order rather than a vague aspiration.
