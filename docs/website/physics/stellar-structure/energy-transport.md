# Energy Transport

Energy transport tells the star how temperature must fall outward so the generated luminosity can escape. In plain language, the temperature must drop outward fast enough for the local luminosity to be carried through each shell.

The shorthand form is `dT/dm`. The important physical caution is that the transport equation needs an **active** temperature gradient, not automatically a radiative one. ASTRA currently uses a radiative-gradient closure in the residual as a bootstrap limitation, not as the intended long-term transport law.

## Continuous equation

$$
\frac{dT}{dm} = -\frac{G m T}{4 \pi r^4 P} \nabla
$$

Here $T$ is temperature, $P$ is pressure, and `nabla = d log(T) / d log(P)` means

$$
\nabla \equiv \frac{d \log T}{d \log P}
$$

for the dimensionless temperature gradient. Physically, $\nabla$ measures how quickly temperature changes compared to pressure through the star. The logarithms are not cosmetic notation here; they are built into the definition of the transport gradient itself.

The symbol $\nabla$ is branch-owned:

- in a radiatively stable zone, $\nabla = \nabla_\mathrm{rad}$,
- in a convectively unstable zone, $\nabla$ should come from the convective closure.

That distinction is central to ASTRA's current scientific hardening. The exact notation matters here: the ASTRA row is built from `log(T)` and `log(P)`, not from raw temperatures and pressures.

## Log-form view

Because

$$
\nabla \equiv \frac{d \log T}{d \log P},
$$

the transport equation can also be written as

$$
\frac{d \log T}{dm} = -\frac{G m}{4 \pi r^4 P} \nabla.
$$

That form makes the solver logic clearer: the row really couples logarithmic temperature changes to logarithmic pressure changes. Because $\nabla$ is already defined logarithmically and $\log T$ is solve-owned, the log form is the natural representation for ASTRA's packed basis. It is one of the reasons ASTRA treats $\log T$ as a solve-owned variable instead of $T$ itself.

## Current ASTRA implementation

ASTRA currently writes the transport row in log form:

$$
\log T_{k+1} - \log T_k - \nabla_k \left(\log P_{k+1} - \log P_k\right) = 0
$$

Here, $\log T_k$ and $\log P_k$ are neighboring cell values, while $\nabla_k$ is the local transport gradient evaluated for cell $k$. This subtracts the `\nabla_k` pressure-difference term. The earlier additive form was inconsistent with the documented `nabla = d log(T) / d log(P)` meaning.

This is the `transport` row in `src/numerics/residuals.jl`. The current `\nabla_k` comes from the radiative helper in `src/numerics/structure_equations.jl`, which combines the staged analytical opacity closure, the staged gas-plus-radiation EOS pressure, the luminosity, and the local enclosed mass.

That is a code-backed fact about the present solver, not the intended long-term physics. The intended physics is branch-owned:

- radiative zones should use the radiative branch,
- convective zones should use a convective closure.

So the present row should be read as "the current bootstrap transport law" rather than "ASTRA's final statement of stellar transport physics."

## Numerical realization in ASTRA

The transport row is assembled in [Residual Assembly](../../methods/residual-assembly.md), and its current derivative handling is described in [Jacobian Construction](../../methods/jacobian-construction.md). The $\log(T)$ and $\log(P)$ form is deliberate: it keeps the row numerically stable while luminosity, pressure, and temperature span many orders of magnitude.

The convection-specific ownership story lives in [Convection](../convection.md), [Radiative Gradient, Schwarzschild, and Ledoux Readiness](../convection/radiative-gradient-and-criterion-hook.md), and [Mixing-Length Theory Target](../convection/mixing-length-theory.md).

## Current validation status

The current dated Armijo validation bundle makes one point sharply: the dominant weighted failure signal is transport-family-local, but it is not exclusively outer-boundary-local. In the committed `2026-03-30` bundle, `interior_transport` dominates the default-12 case and the larger-cell ladder, while `outer_transport` still dominates the smallest `n_cells = 6, 8` runs. Regularized fallback is used everywhere.

That is a measured solver diagnostics result, not yet a proof that the radiative-gradient law itself is wrong. The sharper current hypothesis is narrower: the present transport bottleneck is mixed between interior transport and the one-sided outer transport interface, so ASTRA should harden that evidence surface before claiming a purely boundary-local cause.

## Current status vs target model

Current code:

- the transport residual uses the radiative gradient helper,
- the convection hook can classify stability,
- but the active transport row does not yet switch branches.

Near-term canonical target:

- the active $\nabla$ becomes branch-owned,
- stable cells use the radiative branch,
- unstable cells use Bohm-Vitense local MLT,
- the first implementation is Schwarzschild-active and Ledoux-ready.

Later target:

- Ledoux-active transport where composition gradients matter,
- convective composition mixing,
- richer surface-convection and nonlocal refinements.

## What is deferred

Real mixing-length theory, convective overshoot, semiconvection, thermohaline transport, and composition transport are deferred from the active residual today. The present transport row is radiative-gradient-only and should be read as a bootstrap closure, not a finished convective model.
