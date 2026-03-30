# Boundary Condition Realization

ASTRA realizes the boundary conditions as residual rows, not as special-cased solver magic.

## Center asymptotic realization

The inner face uses asymptotic center targets for radius and luminosity:

$$
r_\mathrm{inner} = \left(\frac{3 m_\mathrm{inner}}{4 \pi \rho_c}\right)^{1/3}
$$

$$
L_\mathrm{inner} = m_\mathrm{inner} \, \varepsilon_\mathrm{nuc}
$$

That is the center asymptotic closure ASTRA now solves instead of the older subtractive-cancellation form. The old shell-volume center row and the old `L_face[1] = 0` style behavior were exactly the kind of inner-boundary numerics that could stall the bootstrap solve.

## Surface closure

The surface rows are still provisional closure rows for radius, luminosity, temperature, and density. They make the problem square and numerically stable, but they are not a finished atmosphere model.

## Why this matters

The page exists so future readers can see the boundary conditions as explicit discrete residuals. That makes the center asymptotic choice and the surface closure tradeoff visible instead of hidden inside the solver.

The continuous boundary story is summarized in [Physics: Boundary Conditions](../physics/boundary-conditions.md). For the closest source-backed MESA comparison on center ownership and boundary-side special handling, see [MESA Reference: Boundary Conditions](mesa-reference/boundary-conditions.md).
