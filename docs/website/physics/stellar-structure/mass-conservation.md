# Mass Conservation

Mass conservation is the geometric equation that turns enclosed mass into radius. In mass coordinate, it says that a thin shell of mass occupies a spherical shell volume set by the local density.

The shorthand form is `dr/dm`, which is the exact row label ASTRA uses in the physics discussion even though the code stores the residual in discrete shell-volume form.

## Continuous equation

$$
\frac{dr}{dm} = \frac{1}{4 \pi r^2 \rho}
$$

Here $r$ is the radius, $m$ is enclosed mass, and $\rho$ is the local mass density. The equation is purely geometric, but it couples immediately to the EOS because `rho` is solved from pressure and temperature.

## Current ASTRA implementation

ASTRA currently writes this row as a shell-volume closure in the interior residual:

$$
\mathrm{shell\_volume}(r_k, r_{k+1}) - \frac{dm_k}{\rho_k} = 0
$$

In code, that is the `geometry` row in `src/numerics/residuals.jl`:

```julia
shell_volume_cm3(r_left_cm, r_right_cm) - dm_g / clip_positive(density_k_g_cm3)
```

`r_left_cm` and `r_right_cm` are face-centered radii, while `density_k_g_cm3` is the cell-centered density. The use of `clip_positive` is a numerical guard only; it does not change the underlying equation.

## Numerical realization in ASTRA

The geometry row is assembled by [Residual Assembly](../../methods/residual-assembly.md), and the row's Jacobian structure is described in [Jacobian Construction](../../methods/jacobian-construction.md). The state ownership and face/cell staggering are described in [Staggered Mesh and State Layout](../../methods/staggered-mesh-and-state-layout.md).

## What is deferred

This page describes the classical baseline only. Real atmospheric structure, time-dependent hydrodynamics, rotation, and composition transport are deferred. The current ASTRA lane is a static 1D bootstrap solve, not a full evolution code.
