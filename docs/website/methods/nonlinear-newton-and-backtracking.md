# Nonlinear Newton and Backtracking

ASTRA's nonlinear loop is a plain Newton solve with damping, backtracking, and a regularization retry ladder.

## Step acceptance

Each iteration evaluates the residual, builds the Jacobian, solves for a correction, and then tries a damped update. If the residual norm drops, the step is accepted. If not, the damping factor is cut in half and the trial is retried.

The current public example demonstrates the behavior clearly: the 24-cell demo reaches `8` accepted steps, `289` rejected trials, and a residual drop from `2.1962008371612166e22` to `1.1903032914682583e19`, while still returning `converged = false`.

## Rejected trials

Rejected trials are not noise to hide. They are evidence that the current basin is still narrow, even though the solver now finds a residual-reducing direction on the placeholder-closure stack.

## Regularization

If the direct solve is singular or the update is non-finite, ASTRA retries the Newton subproblem with regularized normal equations on the same scaled Jacobian. That is a solver robustness feature, not a physics change.

## Why this matters

The point of the page is to show the exact acceptance logic future developers are hardening: a damped Newton update, not a heuristic relaxation loop.
