# Stellar Structure

The classical 1D stellar-structure problem is built from four coupled ideas:

- mass continuity,
- hydrostatic equilibrium,
- energy conservation,
- energy transport.

ASTRA's long-term classical baseline will turn those into a coupled nonlinear solve in the enclosed-mass coordinate.

The approved state staggering for that solve is:

- face-centered radius and luminosity,
- cell-centered density and temperature.

That is a physically natural arrangement for a 1D mass-coordinate stellar code and is consistent with the common MESA-style structure layout documented in its developer materials.

## Current status

The current repository now implements a first classical residual on the approved staggered structure state. The interior rows carry:

1. a geometric shell-volume closure,
2. a hydrostatic-equilibrium closure,
3. a luminosity-generation closure using placeholder nuclear heating,
4. and a transport closure built from a radiative gradient estimate.

That is an important step forward from the earlier teaching scaffold, but it is still not yet a validated solar model. The EOS, opacity, nuclear, convection, and surface layers remain intentionally simple placeholder closures for this milestone.
