# Jacobian Construction

ASTRA's Jacobian is intentionally split by derivative fidelity.

The important numerical contract is that the Jacobian is taken with respect to the packed solve variables,

$$
x = \left(\log r,\; L,\; \log T,\; \log \rho \right),
$$

not with respect to an auxiliary vector of raw physical variables. That means local closure derivatives must be promoted into packed-variable derivatives with the appropriate chain rule factors.

## Normative derivative-basis contract

For the current classical solve, Jacobian entries should be interpreted as

$$
J_{ij} = \frac{\partial R_i}{\partial x_j},
$$

where $x_j$ runs over the packed state

$$
x = \left(\log r,\; L,\; \log T,\; \log \rho \right).
$$

That means a closure derivative is only solver-ready once it has been converted into this basis. A raw derivative such as $\partial P / \partial T$ is useful, but it is not yet the actual Jacobian entry for a $\log T$ solve variable.

This distinction is where many solver bugs hide. A closure can be mathematically correct in physical variables and still enter the Newton system incorrectly if the packed-variable chain rule is missed or applied with the wrong owner convention. ASTRA therefore treats the derivative basis itself as part of the specification.

## Analytic rows

The current structured Jacobian has exact local partials for the analytic rows:

- the center radius row,
- the center luminosity row,
- the interior geometry rows,
- the interior luminosity rows.

Those rows use explicit derivatives from the staged analytical EOS and local helper derivatives from the staged analytical opacity and nuclear closures. The relevant closure definitions live in [Physics: Equation of State](../physics/eos.md), [Physics: Opacity](../physics/opacity.md), [Physics: Nuclear Energy Generation](../physics/nuclear.md), and [Physics: Radiative Gradient and Criterion Hook](../physics/convection/radiative-gradient-and-criterion-hook.md).

For example, if a local kernel naturally provides $\partial f / \partial T$ and $\partial f / \partial \rho$, the packed-state Jacobian should use

$$
\frac{\partial f}{\partial \log T} = T \frac{\partial f}{\partial T},
\qquad
\frac{\partial f}{\partial \log \rho} = \rho \frac{\partial f}{\partial \rho}.
$$

That is why ASTRA's analytic luminosity-row partials carry explicit factors of $T$ and $\rho$ in the current code.

The current analytic coverage is intentionally modest but meaningful. ASTRA chose the rows where the ownership story is already clean enough to make analytic derivatives educational rather than fragile, while letting the opacity and nuclear closures use explicit ASTRA-owned local derivative helpers. That makes the Jacobian a contributor surface, not just a black-box matrix builder.

## Central differences

The hydrostatic rows, transport rows, and surface boundary rows still rely on local central differences. That is deliberate: the page should not pretend the Jacobian is fully analytic when it is not.

The fallback rows are still in the correct packed-variable basis because the finite-difference perturbations are applied directly to the packed state rather than to a separate physical-variable vector.

## Audit hook

The row-family split is tracked by `jacobian_fidelity_audit`. That helper compares the analytic and fallback pieces against independent row-local finite differences so we can see whether a Jacobian improvement is real before we claim it helped Newton.

## Why this matters

The structured Jacobian is the difference between "the solver is trying something" and "the solver knows which row depends on which state block." It is also the place where future analytic coverage should be added first.

The relevant physics owners for those derivatives are the [Equation of State](../physics/eos.md), [Opacity](../physics/opacity.md), [Nuclear Energy Generation](../physics/nuclear.md), and [Convection](../physics/convection.md) pages.

## Implementation checklist

- [x] The Jacobian basis is stated in terms of packed solve variables.
- [x] The analytic rows are named explicitly.
- [x] The fallback rows are named explicitly.
- [x] The page documents that central differences are applied in packed-variable basis.
- [ ] Every analytic row is linked to a test or audit artifact with a quantitative tolerance.

## Validation checklist

- [x] `jacobian_fidelity_audit` is identified as the current row-family audit hook.
- [ ] The fallback hydrostatic, transport, and surface rows are replaced or bounded by stronger quantitative audits before this page can claim production-grade status.

## Open-risk checklist

- [x] The current Jacobian is not described as fully analytic.
- [ ] The page should eventually carry a row-family table showing exact code ownership and current derivative fidelity for every residual family.
