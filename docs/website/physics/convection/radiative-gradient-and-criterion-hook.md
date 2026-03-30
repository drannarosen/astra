# Radiative Gradient and Criterion Hook

ASTRA's current convection story is intentionally narrow: it computes a radiative gradient helper and a criterion hook, but the residual still uses radiative transport.

## Current formula

The helper in `src/numerics/structure_equations.jl` computes

$$
\nabla_\mathrm{rad} = \frac{3 \kappa L P}{16 \pi a c G m T^4}
$$

where `kappa` comes from the staged analytical opacity closure, `L` is face-centered luminosity, `P` is EOS pressure, `m` is enclosed mass, and `T` is cell temperature.

The criterion hook compares `nabla_rad` against `nabla_ad`, and in the current staged gas-plus-radiation EOS `nabla_ad` is computed from the local gas-pressure fraction rather than fixed to `0.4`.

## Derivative payloads ASTRA uses

The helper's derivative story is built from the EOS and opacity payloads:

$$
\frac{d\kappa}{dT}, \quad \frac{d\kappa}{d\rho}, \quad \frac{dP}{dT}, \quad \frac{dP}{d\rho}
$$

The docs also spell these as `dκ/dT`, `dκ/drho`, `dP/dT`, and `dP/drho` so the literal payload names stay visible.

Those derivatives are what the Jacobian construction checks when it validates the transport row and its local sensitivities.

## How it enters ASTRA

The current classical solve still writes the transport residual in radiative form:

$$
\log T_{k+1} - \log T_k + \nabla_k \left(\log P_{k+1} - \log P_k\right) = 0
$$

So the criterion hook is diagnostic scaffolding around a radiative transport row, not a full convection model.

The discrete transport row is described in [Residual Assembly](../../methods/residual-assembly.md), and the current derivative checks are summarized in [Jacobian Construction](../../methods/jacobian-construction.md).

## What is deferred

Real mixing-length theory, convective overshoot, semiconvection, thermohaline transport, and composition transport are deferred. This page documents the current radiative-gradient helper and criterion hook only.
