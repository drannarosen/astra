# Boundary Conditions

Boundary conditions are not side details in a stellar code. They are part of the model definition.

ASTRA's first classical residual now uses deliberately minimal physical closures:

- a center shell-volume closure for the innermost cell,
- a center luminosity closure with `L_face[1] = 0`,
- a surface radius closure against the declared stellar-radius guess,
- a surface luminosity closure against the declared luminosity guess,
- a surface temperature closure against the declared effective-temperature guess,
- and a surface density closure against a simple atmosphere-density guess.

The center treatment is physically motivated enough for the first residual slice. The surface closure is still provisional, because the current milestone is about replacing the toy interior rows with real equation semantics, not about pretending the atmosphere treatment is finished.
