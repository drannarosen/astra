# From Equations to Residual

This page shows how ASTRA turns the continuous classical equations into a residual vector. The important bridge is between the `Physics` pages and the solver-side `Methods` pages.

## Unknown vector

ASTRA packs the structure state as

```text
[ log(radius_face_cm),
  luminosity_face_erg_s,
  log(temperature_cell_k),
  log(density_cell_g_cm3) ]
```

That is the unknown vector the Newton solve updates. The `log(radius` and `log(temperature` choices are there for positivity and conditioning; luminosity stays linear in raw `erg/s` because it crosses zero at the center and is still a physical flux variable.

## Residual vector

The residual vector follows the same physical order:

- center boundary rows,
- interior structure blocks,
- surface boundary rows.

Each interior block contributes the geometry, hydrostatic, luminosity, and transport rows. That ordering is not arbitrary; it matches the ownership of the solve variables and the way the Jacobian is built.

## Why this matters

Once the equations are written as a residual vector, ASTRA can ask Newton's method for a coupled correction instead of integrating shell by shell. That is the difference between a true boundary-value solve and a reference-profile comparison.
