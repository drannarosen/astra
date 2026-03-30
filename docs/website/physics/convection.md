# Convection

Convection decides whether radiative diffusion is enough to carry the flux or whether buoyant fluid motion must help. In classical stellar theory, that requires at least two layers of logic:

- a stability criterion that asks whether a stratification is unstable,
- and a transport closure that replaces purely radiative transport in unstable zones.

In ASTRA's bootstrap lane, only the first layer exists today.

## Current ASTRA implementation

The current **criterion hook** compares a radiative-gradient estimate to the EOS adiabatic gradient and classifies the local regime as radiative or convective. That is enough to show where a future convection model belongs in the code, but it is not yet a mixing-length transport closure and it does not alter the transport residual.

## Numerical realization in ASTRA

The radiative-gradient helper lives in the methods layer and is used by the transport row in [Residual Assembly](../methods/residual-assembly.md). The derivative story for that helper is tracked in [Jacobian Construction](../methods/jacobian-construction.md), and the present validation lane is summarized in [Verification and Jacobian audits](../methods/verification-and-jacobian-audits.md).

## What is deferred

Real MLT, overshoot, semiconvection, thermohaline mixing, and composition transport are deferred. The current hook is intentionally narrow: it classifies a region so the code can stay honest about what transport physics is and is not implemented.
