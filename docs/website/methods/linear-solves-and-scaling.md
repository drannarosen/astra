# Linear Solves and Scaling

ASTRA keeps solve-owned luminosity in raw `erg/s` and uses column scaling for conditioning instead of rewriting the physical variable.

## Column scaling

The scaling vector is built from the packed state so the Newton correction sees geometry, temperature, density, and luminosity on comparable numerical footing. The luminosity scale is based on the current model values and the problem luminosity guess, with `SOLAR_LUMINOSITY_ERG_S` as a floor.

That is numerical conditioning, not a change in variable ownership.

## Linear solve

The current direct solve is a dense backslash solve. If that fails or returns a non-finite update, ASTRA retries with regularized normal equations on the same scaled system.

## Regularized normal equations

The regularization ladder is the fallback path when the direct linearized step is singular or unhelpful. It does not change the equations; it only changes how ASTRA solves the Newton subproblem.

## Why this matters

The current bootstrap lane is small enough that dense algebra is acceptable, but the explicit linear-solver boundary makes it clear where a future sparse or external solver would enter without changing the nonlinear ownership contract.
