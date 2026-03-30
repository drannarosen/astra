# Energy Generation

Energy generation tells the star where luminosity comes from and where it is lost. In a full classical stellar-structure solve, the luminosity equation should track all local gain and loss terms, not only nuclear heating.

In plain language, the luminosity at a given shell is built up by adding local energy sources and subtracting local losses inside that shell.

The shorthand form is `dL/dm`, and the source terms are often written as `eps_nuc`, `eps_grav`, and `eps_nu` in code and notes. ASTRA now assembles those terms through a source-decomposed helper lane, even though the gravothermal term depends on evolution history and the microphysics pieces are still staged.

## Continuous equation

$$
\frac{dL}{dm} = \varepsilon_\mathrm{nuc} + \varepsilon_\mathrm{grav} - \varepsilon_\nu
$$

Here $L$ is luminosity, $\varepsilon_\mathrm{nuc}$ is the specific nuclear energy generation rate, $\varepsilon_\mathrm{grav}$ is the gravothermal term, and $\varepsilon_\nu$ is the specific neutrino-loss term, all in $\mathrm{erg\,g^{-1}\,s^{-1}}$. The equation says luminosity grows outward by integrating local heating and cooling terms. ASTRA now owns this source-decomposed form in the residual helper layer rather than only the nuclear contribution.

This is one of the most important places to be explicit about what is mathematically complete and what is only partially implemented. The full classical equation is not optional bookkeeping. It is the energy-conservation statement the stellar model is supposed to satisfy.

The gravothermal term matters whenever the star stores or releases internal energy through contraction or expansion. Even without nuclear burning, a contracting star can still shine by releasing gravothermal energy. The neutrino term matters whenever local thermal or nuclear conditions allow energy to escape without remaining in the radiation field. A serious stellar code must eventually own all of these terms explicitly.

One useful way to read the equation is as an energy-budget sentence:

- `eps_nuc` adds luminosity because nuclear reactions deposit energy locally,
- `eps_grav` adds or subtracts luminosity depending on whether the fluid is releasing or storing thermal/gravitational energy,
- `eps_nu` removes luminosity from the radiation-plus-gas budget because neutrinos escape.

That reading matters numerically because it tells us which source terms should be grouped together in the same residual row and which signs must remain visible in the implementation.

## Log-form view

ASTRA does **not** solve a logarithmic luminosity variable today, because luminosity crosses zero at the center and is naturally face-centered as a signed flux quantity. The luminosity equation therefore remains in linear $L$ even when neighboring solve variables are logarithmic.

This mixed basis is deliberate rather than inconsistent. Radius, temperature, and density benefit from logarithmic solves because positivity and dynamic range dominate their conditioning story. Luminosity is different. Near the center it should approach zero smoothly, and a log-luminosity variable would turn that benign physical limit into a numerical singularity.

## Current ASTRA implementation

ASTRA currently uses the luminosity row

$$
L_{k+1} - L_k - dm_k \, \left(\varepsilon_{\mathrm{nuc},k} + \varepsilon_{\mathrm{grav},k} - \varepsilon_{\nu,k}\right) = 0
$$

Here, $L_k$ and $L_{k+1}$ are the shell's inner and outer face luminosities, while $dm_k$ and $\varepsilon_{\mathrm{nuc},k}$ belong to the cell between them.

ASTRA writes this row as a luminosity difference across a shell because luminosity is face-centered while the source term is cell-centered on the staggered mesh.

As implemented in `src/numerics/residuals.jl`, the source term now comes from a source-decomposed helper in `src/microphysics/energy_sources.jl` and is surfaced through `src/numerics/structure_equations.jl`, so this page should be read as the exact source ASTRA actually uses today.

In other words:

- the **full classical equation** owns $\varepsilon_\mathrm{nuc}$, $\varepsilon_\mathrm{grav}$, and $\varepsilon_\nu$,
- the **current ASTRA residual** owns the assembled `eps_nuc + eps_grav - eps_nu` source term.

## Numerical realization in ASTRA

The luminosity row is assembled in [Residual Assembly](../../methods/residual-assembly.md), and the local source derivatives are tracked in [Jacobian Construction](../../methods/jacobian-construction.md). The solver keeps luminosity in raw cgs $\mathrm{erg\,s^{-1}}$; it is not rewritten as a solar-unit variable or a log-luminosity variable. ASTRA's `eps_grav` term is evolution-owned because it depends on previous accepted thermodynamic history, while `eps_nu` is a staged analytical loss term inside the same residual-owned source decomposition.

## What is deferred

Real reaction networks and composition evolution are deferred. The current closure is still a bootstrap source term, not a production energy-balance model. The public closure payload still excludes abundance time derivatives even though the reference Stellax source tracks them internally, and the current `eps_grav` implementation requires evolution history rather than a wider solve contract.

## Implementation checklist

- [x] The full classical luminosity equation includes `eps_nuc`, `eps_grav`, and `eps_nu`.
- [x] The current ASTRA row is stated separately from the full classical equation.
- [x] The linear luminosity solve basis is explained explicitly.
- [x] The current evolution history requirement for `eps_grav` is written explicitly.

## Validation checklist

- [ ] Signs and units of the luminosity row are verified against a benchmark artifact rather than only code inspection.
- [ ] A source-decomposed validation artifact exists showing the relative size of `eps_nuc`, `eps_grav`, and `eps_nu` for at least one representative model.
- [ ] The center luminosity asymptotic behavior is checked after `eps_grav` and `eps_nu` are introduced.

## Deferred-scope checklist

- [x] `eps_grav` is implemented as an evolution-owned analytical helper, not as a solve-owned closure payload.
- [x] `eps_nu` is implemented as a staged analytical loss term inside the residual-owned source decomposition.
- [x] Composition-coupled nuclear source evolution is not yet implemented.
