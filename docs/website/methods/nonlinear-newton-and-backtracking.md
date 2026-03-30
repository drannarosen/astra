# Nonlinear Newton and Backtracking

ASTRA's nonlinear loop is a plain Newton solve with damping, backtracking, and a regularization retry ladder.

This page describes the current Newton transcript: damping, backtracking, regularized fallback, and what ASTRA records as accepted or rejected trials.

The canonical specification for the current weighted acceptance metrics and the longer-term merit-function direction now lives in [Nonlinear Step Metrics and Globalization](nonlinear-step-metrics-and-globalization.md).

The guiding idea is intentionally conservative: ASTRA should not "hide" a bad Newton step by quietly changing the model definition. It should keep the same residual, the same packed-variable basis, and the same physics ownership, then decide whether a proposed correction genuinely improves the coupled solve.

## Step acceptance

Each iteration evaluates the residual, builds the Jacobian, solves for a correction, applies a weighted correction limiter, and then tries a damped update. If the frozen-weight merit function drops and the raw residual norm does not increase, the step is accepted. If not, the damping factor is cut in half and the trial is retried.

That means ASTRA's current acceptance rule is still a modest damped-Newton controller, not yet a full trust-region strategy or line-search merit method. The value of writing that down explicitly is that future changes can be judged against a known baseline instead of slipping in as undocumented solver folklore.

## Normative acceptance contract

For the current classical lane, a trial Newton step is accepted only if it lowers the frozen-weight merit function on the same residual definition and does not increase the raw residual norm. Backtracking changes the damping factor, but it does not change the residual, the packed-variable basis, or the physical ownership of the equations.

The merit objective is a frozen-weight merit function built from the base iterate's row weights. That is the current scientifically explicit controller backbone. It is stronger than the old weighted-norm wording, but it is still not yet a predicted-versus-actual line-search method.

If the direct solve is singular or produces a non-finite update, ASTRA may retry the same linearized subproblem with regularized normal equations. That is still part of the same nonlinear step, not a different physics model.

The current 12-cell default test fixture still demonstrates the same qualitative behavior clearly: ASTRA accepts a real step, records many rejected trials, lowers the controller objective, lowers the raw residual norm, and still returns `converged = false`. The important point for this page is the acceptance contract, not a permanently frozen benchmark number.

## Rejected trials

Rejected trials are not noise to hide. They are evidence that the current basin is still narrow, even though the solver now finds a residual-reducing direction on the placeholder-closure stack.

That is why the diagnostics keep both accepted and rejected counts. For a research code, a high rejected-trial count can be as informative as a low residual norm, because it tells us whether conditioning, boundary handling, or derivative quality is still fighting the method.

## Regularization

If the direct solve is singular or the update is non-finite, ASTRA retries the Newton subproblem with regularized normal equations on the same scaled Jacobian. That is a solver robustness feature, not a physics change.

## Why this matters

The point of the page is to show the exact acceptance logic future developers are hardening: a damped Newton update, not a heuristic relaxation loop.

## Implementation checklist

- [x] Step acceptance is defined by frozen-weight merit reduction on the same residual, with a raw-residual safeguard.
- [x] Damping/backtracking is described as a modification of step size, not of physics ownership.
- [x] Regularization is described as a linear-subproblem fallback, not a different model.
- [x] The current page points to the canonical step-metric specification.

## Validation checklist

- [x] The public 24-cell demo evidence is summarized here.
- [ ] The same acceptance logic is exercised on more than one representative model family before this page can claim robust Newton behavior.

## Open-risk checklist

- [x] The page says the current basin is still narrow.
- [ ] Domain-aware rejection safeguards and stronger globalization logic remain future work.
