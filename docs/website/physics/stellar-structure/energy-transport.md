# Energy Transport

Energy transport tells the star how temperature must fall outward so the generated luminosity can escape. ASTRA currently uses the radiative-gradient form of the transport equation, expressed in logarithmic state variables for numerical robustness.

The shorthand form is `dT/dm`, and the current closure is a radiative gradient, not a full MLT transport model.

## Continuous equation

$$
\frac{dT}{dm} = -\frac{G m T}{4 \pi r^4 P} \nabla
$$

Here $T$ is temperature, $P$ is pressure, and `nabla = d log(T) / d log(P)` means

$$
\nabla \equiv \frac{d \log T}{d \log P}
$$

for the dimensionless temperature gradient. In other words, the literal numerator `d \log T` is part of the transport specification rather than a stylistic choice. The current classical ASTRA lane computes a radiative gradient estimate for `nabla`; it does not yet solve a full MLT closure. The exact notation matters here: the ASTRA row is built from `log(T)` and `log(P)`, not from raw temperatures and pressures.

## Log-form view

Because

$$
\nabla \equiv \frac{d \log T}{d \log P},
$$

the transport equation can also be written as

$$
\frac{d \log T}{dm} = -\frac{G m}{4 \pi r^4 P} \nabla.
$$

That form makes the solver logic clearer: the row really couples logarithmic temperature changes to logarithmic pressure changes. It is one of the reasons ASTRA treats $\log T$ as a solve-owned variable instead of $T$ itself.

## Current ASTRA implementation

ASTRA currently writes the transport row in log form:

$$
\log T_{k+1} - \log T_k + \nabla_k \left(\log P_{k+1} - \log P_k\right) = 0
$$

This is the `transport` row in `src/residuals.jl`. The gradient `nabla_k` comes from the helper in `src/structure_equations.jl`, which combines the toy opacity law, the EOS pressure, the luminosity, and the local enclosed mass.

## Numerical realization in ASTRA

The transport row is assembled in [Residual Assembly](../../methods/residual-assembly.md), and its current derivative handling is described in [Jacobian Construction](../../methods/jacobian-construction.md). The $\log(T)$ and $\log(P)$ form is deliberate: it keeps the row numerically stable while luminosity, pressure, and temperature span many orders of magnitude.

## What is deferred

Real mixing-length theory, convective overshoot, semiconvection, thermohaline transport, and composition transport are deferred. The present transport row is radiative-gradient-only and should be read as a bootstrap closure, not a finished convective model.
