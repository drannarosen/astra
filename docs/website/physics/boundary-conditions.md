# Boundary Conditions

Boundary conditions are not side details in a stellar code. They are part of the model definition.

ASTRA's first classical residual now uses deliberately minimal physical closures:

- a center asymptotic radius closure for the innermost face using the leading-order spherical-series target,
- a center asymptotic luminosity closure for the innermost face using the leading-order integrated source target,
- a surface radius closure against the declared stellar-radius guess,
- a surface luminosity closure against the declared luminosity guess,
- a surface temperature closure against the declared effective-temperature guess,
- and a surface density closure against a simple atmosphere-density guess.

The center treatment is still deliberately bootstrap-level, but it is no longer the old numerically fragile shell-volume closure plus `L_face[1] = 0` pair. ASTRA now enforces the leading-order center asymptotics directly at the inner face so the first zone is not asked to satisfy a subtractive-cancellation constraint that Float64 resolves poorly.

The surface closure is still provisional, because the current milestone is about replacing the toy interior rows with real equation semantics, not about pretending the atmosphere treatment is finished.
