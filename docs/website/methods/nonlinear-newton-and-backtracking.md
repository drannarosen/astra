# Nonlinear Newton and Backtracking

ASTRA's nonlinear loop is a plain Newton solve with damping, backtracking, and a regularization retry ladder.

This page is the canonical specification for the current nonlinear acceptance logic.

The guiding idea is intentionally conservative: ASTRA should not "hide" a bad Newton step by quietly changing the model definition. It should keep the same residual, the same packed-variable basis, and the same physics ownership, then decide whether a proposed correction genuinely improves the coupled solve.

## Step acceptance

Each iteration evaluates the residual, builds the Jacobian, solves for a correction, and then tries a damped update. If the residual norm drops, the step is accepted. If not, the damping factor is cut in half and the trial is retried.

That means ASTRA's current acceptance rule is a residual-reduction rule, not yet a full trust-region strategy, line-search merit function, or physics-aware safeguard suite. The value of writing that down explicitly is that future changes can be judged against a known baseline instead of slipping in as undocumented solver folklore.

## Normative acceptance contract

For the current classical lane, a trial Newton step is accepted only if it lowers the residual norm on the same residual definition. Backtracking changes the damping factor, but it does not change the residual, the packed-variable basis, or the physical ownership of the equations.

If the direct solve is singular or produces a non-finite update, ASTRA may retry the same linearized subproblem with regularized normal equations. That is still part of the same nonlinear step, not a different physics model.

The current public example demonstrates the behavior clearly: the 24-cell demo reaches `8` accepted steps, `289` rejected trials, and a residual drop from `2.1962008371612166e22` to `1.1903032914682583e19`, while still returning `converged = false`.

## Rejected trials

Rejected trials are not noise to hide. They are evidence that the current basin is still narrow, even though the solver now finds a residual-reducing direction on the placeholder-closure stack.

That is why the diagnostics keep both accepted and rejected counts. For a research code, a high rejected-trial count can be as informative as a low residual norm, because it tells us whether conditioning, boundary handling, or derivative quality is still fighting the method.

## Regularization

If the direct solve is singular or the update is non-finite, ASTRA retries the Newton subproblem with regularized normal equations on the same scaled Jacobian. That is a solver robustness feature, not a physics change.

## Why this matters

The point of the page is to show the exact acceptance logic future developers are hardening: a damped Newton update, not a heuristic relaxation loop.

## Implementation checklist

- [x] Step acceptance is defined by residual reduction on the same residual.
- [x] Damping/backtracking is described as a modification of step size, not of physics ownership.
- [x] Regularization is described as a linear-subproblem fallback, not a different model.
- [ ] The current page should eventually document the exact residual norm used for acceptance and convergence in one place.

## Validation checklist

- [x] The public 24-cell demo evidence is summarized here.
- [ ] The same acceptance logic is exercised on more than one representative model family before this page can claim robust Newton behavior.

## Open-risk checklist

- [x] The page says the current basin is still narrow.
- [ ] Domain-aware rejection safeguards and stronger globalization logic remain future work.
