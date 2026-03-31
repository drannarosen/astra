# Mixing-Length Theory Target

This page records ASTRA's canonical target for the convective transport branch. It is now also the physics specification that the active solver implementation is expected to realize.

The intended first serious convective closure is **Bohm-Vitense local MLT**. The architecture should be Schwarzschild-active at first, but Ledoux-ready and mixing-ready from the start.

## Current status vs target model

Current ASTRA behavior is still narrower than real convection:

- the residual uses radiative transport,
- the convection hook only classifies the regime,
- and the returned temperature-gradient hint is not yet the active transport law.

The canonical target is now the active implementation:

- every transport row computes the radiative candidate $\nabla_\mathrm{rad}$,
- every transport row evaluates the local stability criterion,
- radiative cells use $\nabla = \nabla_\mathrm{rad}$,
- unstable cells use the Bohm-Vitense local MLT closure to determine $\nabla = \nabla_\mathrm{conv}$.

That is the scientific point of this page: in a real stellar model, the active $\nabla$ in an unstable zone should be supplied by the convective closure, not by radiative diffusion alone.

## Local MLT assumptions

The first ASTRA MLT lane should be intentionally classical and local:

- convection is represented by buoyant fluid parcels moving over a local mixing length,
- the local background stratification is treated as slowly varying across one parcel excursion,
- the closure is algebraic at each mesh location rather than time dependent,
- and the first implementation should keep composition mixing, overshoot, and turbulent pressure outside the active solve.

This is a disciplined baseline, not a claim that local MLT is the final word on convection.

## Geometric and thermodynamic ingredients

The pressure scale height is

$$
H_P = \frac{P}{\rho g},
\qquad
g = \frac{Gm}{r^2}.
$$

The mixing length is

$$
\ell = \alpha_\mathrm{MLT} H_P,
$$

where $\alpha_\mathrm{MLT}$ is the declared mixing-length parameter. The future solver/config interface should also expose the literal name `alpha_MLT`, because that is the quantity developers will tune, audit, and compare across runs.

The EOS must supply the adiabatic gradient $\nabla_\mathrm{ad}$ and the thermodynamic response coefficient

$$
\delta \equiv -\left(\frac{\partial \ln \rho}{\partial \ln T}\right)_{P,\mu}.
$$

For later Ledoux-ready work, the EOS and composition lane should also support

$$
\phi \equiv \left(\frac{\partial \ln \rho}{\partial \ln \mu}\right)_{P,T},
\qquad
\nabla_\mu \equiv \frac{d \ln \mu}{d \ln P}.
$$

In ASTRA's present analytical EOS notation, `chi_rho` and `chi_T` are already first-class outputs, so the future MLT lane should be documented and implemented in a way that makes $\delta$ and later $\phi$ explicit EOS-owned payloads rather than hidden algebra.

## Radiative and convective fluxes

In diffusion form, the radiative flux can be written

$$
F_\mathrm{rad}
=
\frac{4acT^4}{3\kappa \rho H_P}\,\nabla.
$$

If radiation alone had to carry the entire local flux, the corresponding candidate gradient would be

$$
\nabla_\mathrm{rad}
=
\frac{3\kappa P L}{16\pi ac G m T^4}.
$$

Convection changes the problem because the total flux is split:

$$
F_\mathrm{tot} = F_\mathrm{rad} + F_\mathrm{conv}.
$$

Once a zone is convectively unstable, the physically correct branch is no longer "set $\nabla$ equal to $\nabla_\mathrm{rad}$." Instead, the closure must solve for a temperature gradient that lets radiation and buoyant transport share the flux.

## Buoyancy, velocity, and convective flux

In local MLT, a parcel that moves a distance of order $\ell$ acquires a temperature contrast with the background. The background and parcel gradients are distinguished:

- $\nabla$: the ambient stellar gradient,
- $\nabla_e$: the parcel-element gradient,
- $\nabla_\mathrm{ad}$: the adiabatic limit the parcel approaches when radiative exchange is weak.

The buoyant acceleration scales with the superadiabatic contrast. In the usual local estimate,

$$
v_\mathrm{conv}^2
\sim
\frac{g \delta \ell^2}{8 H_P}\,(\nabla - \nabla_e),
$$

so the convective velocity vanishes in a neutral stratification and grows as the parcel becomes more buoyant.

The convective flux then scales as

$$
F_\mathrm{conv}
\sim
\rho c_P T\, v_\mathrm{conv}\,
\frac{\ell}{2H_P}\,(\nabla - \nabla_e),
$$

which is the standard MLT statement that convection transports enthalpy through correlated temperature and velocity perturbations.

These relations are written here in their structural form because ASTRA has not yet frozen the exact order-unity coefficient normalization in code. The future implementation must do so explicitly and document that choice, but the physics ownership does not depend on whether one adopts the textbook Bohm-Vitense coefficient set or an algebraically equivalent rearrangement of the same local closure.

## Algebraic closure for the active gradient

The purpose of MLT is to determine the active convective gradient

$$
\nabla_\mathrm{conv},
$$

not merely to declare that a zone is unstable.

The local closure combines:

- total-flux balance $F_\mathrm{tot} = F_\mathrm{rad} + F_\mathrm{conv}$,
- the buoyancy relation for $v_\mathrm{conv}$,
- and the parcel-cooling relation that connects $\nabla_e$ to $\nabla_\mathrm{ad}$.

In efficient convection, radiative leakage from the parcel is weak and

$$
\nabla_e \rightarrow \nabla_\mathrm{ad},
$$

so the active gradient approaches but does not have to equal the adiabatic value:

$$
\nabla_\mathrm{ad} \lesssim \nabla_\mathrm{conv} \le \nabla_\mathrm{rad}.
$$

That inequality is why ASTRA should not confuse "convective zone" with "set $\nabla = \nabla_\mathrm{ad}$ everywhere." The adiabatic branch is a useful asymptotic limit and a useful diagnostic, but the actual local MLT closure should solve for the superadiabatic excess rather than erase it.

## Schwarzschild-active first, Ledoux-ready from day one

The first code slice may activate only Schwarzschild branch selection:

$$
\nabla_\mathrm{rad} > \nabla_\mathrm{ad}
\quad \Rightarrow \quad
\text{convectively unstable}.
$$

But the interfaces should be designed immediately for Ledoux-ready operation, where the critical gradient becomes

$$
\nabla_\mathrm{L}
\equiv
\nabla_\mathrm{ad} + \frac{\phi}{\delta}\nabla_\mu.
$$

Then the instability test becomes

$$
\nabla_\mathrm{rad} > \nabla_\mathrm{L}.
$$

That design choice matters because branch selection and composition mixing should eventually be related but not conflated. The transport closure decides the active thermal gradient. The mixing module decides how abundances evolve. ASTRA should reserve room for both from the start.

## Bohm-Vitense first, Henyey later

ASTRA's canonical first closure is Bohm-Vitense local MLT. That is the right initial target because it gives a real convective branch without forcing the code to solve the optically thin surface-loss problem in the same slice.

Later refinements may include Henyey-style radiative-loss corrections near the surface, where optically thin effects make the simple optically thick local closure less trustworthy. Those later refinements should be presented as extensions of the convection module, not as reasons to keep the current radiative-only residual alive.

## Minimum future implementation payload

The future MLT lane should make the following quantities explicit rather than implicit:

- EOS-owned: $P$, $\nabla_\mathrm{ad}$, `chi_rho`, `chi_T`, $\delta$, and later $\phi$,
- transport-owned: $\nabla_\mathrm{rad}$, $\nabla_\mathrm{conv}$, superadiabatic excess, convective regime,
- diagnostics-owned: convective flux fraction, convective velocity, and later $\mu$-gradient diagnostics.

Those are the minimum quantities needed to keep the solver scientifically legible now that convection is no longer just a placeholder.

## What is deferred

This page does not claim that ASTRA already implements:

- local MLT in the residual,
- Ledoux-active transport,
- convective composition mixing,
- overshoot,
- semiconvection,
- thermohaline transport,
- or time-dependent convection.

It records the target model only, so that future implementation work does not drift back into "radiative transport plus a convective label" and call that physically complete.
