# Jacobian Construction

ASTRA's Jacobian is intentionally split by derivative fidelity.

## Analytic rows

The current structured Jacobian has exact local partials for the analytic rows:

- the center radius row,
- the center luminosity row,
- the interior geometry rows,
- the interior luminosity rows.

Those rows use explicit derivatives from the current toy EOS and nuclear closures.

## Central differences

The hydrostatic rows, transport rows, and surface boundary rows still rely on local central differences. That is deliberate: the page should not pretend the Jacobian is fully analytic when it is not.

## Audit hook

The row-family split is tracked by `jacobian_fidelity_audit`. That helper compares the analytic and fallback pieces against independent row-local finite differences so we can see whether a Jacobian improvement is real before we claim it helped Newton.

## Why this matters

The structured Jacobian is the difference between "the solver is trying something" and "the solver knows which row depends on which state block." It is also the place where future analytic coverage should be added first.
