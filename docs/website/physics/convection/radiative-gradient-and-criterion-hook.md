# Radiative Gradient, Schwarzschild, and Ledoux Readiness

This page records the part of convection physics ASTRA already owns numerically: the radiative candidate gradient and the instability criterion lane. It also records the stronger physics target ASTRA should grow into, so the criterion logic is not mistaken for a full transport model.

## The active-gradient problem

The transport equation uses

$$
\nabla \equiv \frac{d \ln T}{d \ln P},
$$

where $\nabla$ is the active gradient that actually belongs in the transport row. In a purely radiative zone,

$$
\nabla = \nabla_\mathrm{rad}.
$$

In a convectively unstable zone, that identification is generally wrong. The purpose of the instability criterion is therefore not to produce a decorative label. It decides whether the radiative branch is admissible at all.

## Radiative gradient

The helper in `src/numerics/structure_equations.jl` computes the radiative candidate

$$
\nabla_\mathrm{rad} = \frac{3 \kappa L P}{16 \pi a c G m T^4}.
$$

Here:

- $\kappa$ is the Rosseland-mean opacity supplied by the opacity closure,
- $L$ is the local luminosity,
- $P$ is the EOS pressure,
- $m$ is the enclosed mass,
- $T$ is the local temperature,
- $a$ is the radiation constant,
- $c$ is the speed of light,
- $G$ is the gravitational constant.

This formula is the diffusion-theory statement of "how steep the temperature gradient would have to be if radiation alone carried the flux."

## Adiabatic gradient from the EOS

The EOS supplies the adiabatic gradient

$$
\nabla_\mathrm{ad},
$$

which measures how a displaced fluid element changes temperature when it moves adiabatically through pressure space. In ASTRA's staged analytical EOS, $\nabla_\mathrm{ad}$ is not hard-coded to a constant. It is derived from the local thermodynamic response, as documented in [Analytical Gas and Radiation Details](../eos/analytical-eos.md).

That ownership split is physically important:

- opacity and luminosity determine $\nabla_\mathrm{rad}$,
- the EOS determines $\nabla_\mathrm{ad}$,
- the convection criterion compares them.

## Schwarzschild criterion

The present ASTRA hook is Schwarzschild-based:

$$
\nabla_\mathrm{rad} > \nabla_\mathrm{ad}
\quad \Rightarrow \quad
\text{convectively unstable}.
$$

If the inequality is not satisfied, the layer is radiatively stable and the radiative branch remains admissible.

That is exactly what the current `SchwarzschildConvectionHook` does in code: it compares `nabla_rad` against `nabla_ad`, returns a regime label, and returns a temperature-gradient hint.

## Ledoux-ready extension

For a composition-stratified medium, the instability criterion should eventually become Ledoux-aware. Define

$$
\nabla_\mu \equiv \frac{d \ln \mu}{d \ln P},
$$

and

$$
\phi \equiv \left(\frac{\partial \ln \rho}{\partial \ln \mu}\right)_{P,T},
\qquad
\delta \equiv -\left(\frac{\partial \ln \rho}{\partial \ln T}\right)_{P,\mu}.
$$

Then the Ledoux critical gradient is

$$
\nabla_\mathrm{L}
\equiv
\nabla_\mathrm{ad} + \frac{\phi}{\delta}\nabla_\mu,
$$

and the corresponding instability criterion is

$$
\nabla_\mathrm{rad} > \nabla_\mathrm{L}.
$$

The docs also spell these quantities as `nabla_mu` and `nabla_L` so the future code and diagnostics can keep a literal symbol vocabulary that is easy to grep.

ASTRA does not yet solve with that criterion, but the documentation and future interfaces should be built so this extension is natural rather than invasive.

## Branch ownership

The key physical rule is:

- stable zone: $\nabla = \nabla_\mathrm{rad}$,
- unstable zone: $\nabla$ must come from the convective closure, not from radiative diffusion alone.

That is why this page exists separately from the MLT page. Instability criteria tell ASTRA **whether** the radiative branch fails. They do not by themselves say **what** the active convective gradient should be.

## Derivative payloads ASTRA uses today

The current radiative-gradient helper depends on EOS and opacity response terms such as

$$
\frac{d\kappa}{dT}, \quad \frac{d\kappa}{d\rho}, \quad \frac{dP}{dT}, \quad \frac{dP}{d\rho}.
$$

The docs also spell these as `dκ/dT`, `dκ/drho`, `dP/dT`, and `dP/drho` so the literal payload names stay visible. Those derivatives matter because the current Jacobian work audits the radiative helper and transport row in the packed ASTRA variable basis.

## How it enters ASTRA

The current classical solve still writes the transport residual in radiative form:

$$
\log T_{k+1} - \log T_k - \nabla_k \left(\log P_{k+1} - \log P_k\right) = 0.
$$

That sign convention matches the transport documentation in [Energy Transport](../stellar-structure/energy-transport.md) and the methods derivation in [Residual Assembly](../../methods/residual-assembly.md).

Today, the hook's returned regime and hint do not yet own $\nabla_k$ in that row. So the current residual still uses radiative transport even when the instability hook says the layer is convective. That is a code-backed fact about the current bootstrap lane, not a statement of the intended long-term physics.

The derivative handling for the current helper lane is summarized in [Jacobian Construction](../../methods/jacobian-construction.md).

## What is deferred

Real local MLT, Ledoux-active transport, convective mixing, overshoot, semiconvection, thermohaline transport, and turbulent pressure are deferred from the active residual today. This page therefore documents the current radiative-gradient helper, the current Schwarzschild criterion hook, and the Ledoux-ready mathematical target only.
