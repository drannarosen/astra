# Opacity

Opacity controls how easily radiation carries energy through a stellar layer. In the classical ASTRA lane, it is now a staged analytical closure rather than a single toy power law, but it still feeds the real residual and Jacobian through an explicitly narrow ownership surface.

## Current ASTRA implementation

ASTRA currently uses an analytical opacity closure with three additive components:

- Kramers bound-free/free-free opacity with a temperature-dependent Gaunt factor,
- H-minus bound-free plus free-free opacity in the cool-atmosphere window,
- electron scattering with a Klein-Nishina correction.

The closure is still analytical and fully local in `(rho, T, composition)`, so it remains easy to inspect end to end. Its derivative helpers are still explicit ASTRA-owned functions; the current implementation uses centered local finite differences for the composite temperature and density sensitivities rather than introducing automatic differentiation.

## Numerical realization in ASTRA

Opacity enters the radiative-gradient helper in [Residual Assembly](../methods/residual-assembly.md) and contributes density and temperature derivatives in [Jacobian Construction](../methods/jacobian-construction.md). The method pages explain how the current fallback rows and scaling work around that closure.

## What is deferred

Real opacity tables, conductive opacity, and table-blend hierarchies are deferred. The H-minus term is a simplified analytical proxy, not a production low-temperature opacity table. The current page should be read as the exact staged closure used today, not as a promise about ASTRA's eventual opacity stack.

## Implementation checklist

- [x] The current analytical opacity components are stated explicitly.
- [x] The page says opacity feeds the transport helper and Jacobian path.
- [x] The page says the current derivative helpers are explicit ASTRA-owned local sensitivities.

## Validation checklist

- [ ] The staged analytical opacity closure is benchmarked against a known analytic expectation over a representative state range.
- [ ] Production-grade opacity claims remain deferred until real table or blend validation artifacts exist.
