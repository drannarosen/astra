# Linear Solves and Scaling

ASTRA keeps solve-owned luminosity in raw `erg/s` and uses column scaling for conditioning instead of rewriting the physical variable.

The first layer of conditioning comes from the variable basis itself: radius, temperature, and density are solved in logarithmic form, while luminosity stays linear because it crosses zero at the center. The second layer comes from explicit solver-side scaling of the packed columns.

This page is the canonical specification for the current linearized-solve scaling policy.

That policy is one of the clearest examples of ASTRA's "meaning first, conditioning second" philosophy. The physical variable remains luminosity in cgs units. The numerical machinery is allowed to rescale the linear solve so the Newton step is better behaved, but it is not allowed to quietly redefine the physics variable into something with different ownership or interpretation.

## Column scaling

The scaling vector is built from the packed state so the Newton correction sees geometry, temperature, density, and luminosity on comparable numerical footing. The luminosity scale is based on the current model values and the problem luminosity guess, with `SOLAR_LUMINOSITY_ERG_S` as a floor.

That is numerical conditioning, not a change in variable ownership.

In the current implementation, `src/solvers/linear_solvers.jl` applies unit scaling only to the packed luminosity columns. The log-radius, log-temperature, and log-density columns already benefit from the variable basis itself, so ASTRA currently leaves them at scale 1 in the linear solve. This is a deliberately small conditioning policy rather than a hidden general-purpose preconditioner.

## Normative scaling contract

For the current classical lane, ASTRA's linear solve should satisfy these rules:

1. the Jacobian is formed in the packed-variable basis,
2. the update is solved on a column-scaled system,
3. luminosity remains linear in $\mathrm{erg\,s^{-1}}$,
4. radius, temperature, and density remain logarithmic solve variables,
5. scaling changes conditioning only, not equation ownership or residual meaning.

The same distinction matters for local derivatives. ASTRA's closures may be written in physical variables, but the linear solve should still see derivatives with respect to $\log r$, $\log T$, and $\log \rho$ because those are the packed unknowns.

For the closest file-backed MESA comparison, see [MESA Reference: Solver Scaling](mesa-reference/solver-scaling.md). The physics-side reason luminosity needs special care appears in [Physics: Energy Generation](../physics/stellar-structure/energy-generation.md).

## Linear solve

The current direct solve is a dense backslash solve. If that fails or returns a non-finite update, ASTRA retries with regularized normal equations on the same scaled system.

That direct dense solve is part of the current implementation contract, not an endorsement of dense algebra as the final architecture.

## Regularized normal equations

The regularization ladder is the fallback path when the direct linearized step is singular or unhelpful. It does not change the equations; it only changes how ASTRA solves the Newton subproblem.

## Why this matters

The current bootstrap lane is small enough that dense algebra is acceptable, but the explicit linear-solver boundary makes it clear where a future sparse or external solver would enter without changing the nonlinear ownership contract.

For the physical role of luminosity in the structure equations, see [Energy Generation](../physics/stellar-structure/energy-generation.md). For the source-backed MESA comparison on `x_scale`, correction weights, and energy-equation scaling, see [MESA Reference: Solver Scaling](mesa-reference/solver-scaling.md).

## Implementation checklist

- [x] The page states that luminosity remains a linear solve variable in `erg/s`.
- [x] The page distinguishes solve conditioning from variable ownership.
- [x] The current dense direct solve and regularized fallback are named explicitly.
- [ ] The residual-side scaling policy is documented with the same explicitness as the column-scaling policy.

## MESA parity checklist

- [x] The page points to the dedicated source-backed MESA comparison surface instead of implying parity locally.
- [ ] ASTRA's current luminosity-only column scaling is benchmarked against at least one alternative conditioning strategy before claiming it is the best local policy.

## Open-risk checklist

- [x] Dense linear algebra is described as current implementation, not final architecture.
- [ ] Sparse/block-structured linear algebra entry points are documented before ASTRA expands beyond the current small bootstrap problems.
