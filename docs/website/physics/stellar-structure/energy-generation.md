# Energy Generation

Energy generation tells the star where luminosity comes from. In ASTRA's classical lane, that source term is currently a toy nuclear-heating closure so the luminosity equation can participate in the real residual.

The shorthand form is `dL/dm`, and the source term is written as `eps_nuc` in the methods and test contracts so the placeholder closure stays explicit.

## Continuous equation

$$
\frac{dL}{dm} = \varepsilon_\mathrm{nuc}
$$

Here $L$ is luminosity and $\varepsilon_\mathrm{nuc}$ is the specific nuclear energy generation rate in $\mathrm{erg\,g^{-1}\,s^{-1}}$. The equation says luminosity grows outward by integrating the local source term.
ASTRA keeps the source symbol visible as `eps_nuc` in the discrete discussion below.

## Current ASTRA implementation

ASTRA currently uses the luminosity row

$$
L_{k+1} - L_k - dm_k \, \varepsilon_{\mathrm{nuc},k} = 0
$$

as implemented in `src/residuals.jl`. The source term comes from the toy nuclear closure in `src/structure_equations.jl`, so this page should be read as the exact placeholder source ASTRA actually uses today.

## Numerical realization in ASTRA

The luminosity row is assembled in [Residual Assembly](../../methods/residual-assembly.md), and the local source derivatives are tracked in [Jacobian Construction](../../methods/jacobian-construction.md). The solver keeps luminosity in raw cgs $\mathrm{erg\,s^{-1}}$; it is not rewritten as a solar-unit variable.

## What is deferred

Real reaction networks, composition evolution, neutrino losses, and gravothermal energy terms are deferred. The current closure is a bootstrap source term, not a production nuclear-physics model.
