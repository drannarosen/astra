# Residuals

ASTRA's current residual vector now carries the first classical structure equations on the approved `StellarModel` contract. It is no longer an analytic reference-profile comparison.

Canonical guide: [Residual Assembly](../methods/residual-assembly.md).

The continuous equations are summarized in [Physics: Stellar Structure](../physics/stellar-structure.md). This page remains as a shorter numerics-side note and is not the canonical numerical specification.

The residual is assembled in explicit physical order:

- center boundary rows first,
- interior structure equations next,
- surface boundary rows last.

Within the interior, ASTRA currently carries:

1. geometric or mass-continuity closure,
2. hydrostatic equilibrium,
3. luminosity or energy conservation,
4. temperature-gradient or transport closure.

The energy row now starts the intended source-decomposed pattern by calling a nuclear-heating closure through the residual helper layer. Gravothermal and loss terms are still deferred, so this is only the first step toward the full source-decomposed contract.

## How to read the residual

Read the residual in physical order, not just in array order:

1. center boundary conditions,
2. the interior structure equations for the first cell,
3. the same equation block for the next cell,
4. and finally the surface boundary conditions.

That reading habit makes it much easier to debug ownership mistakes later, because you can ask which physical row is wrong before you ask which array index is wrong.

## Limits of the current slice

This first classical residual still uses placeholder closures:

- ideal-gas-plus-radiation EOS,
- toy Kramers opacity,
- toy pp heating,
- radiative transport only,
- and a provisional surface closure.

Those limitations are explicit. They do not make the residual pedagogical-only again; they simply define the narrow scientific scope of the current slice.

## Summary checklist

- [x] This page explicitly points back to the canonical numerical specification in `Methods`.
- [x] This page explicitly says it is not the canonical numerical specification.
- [ ] Keep this page short as the handbook grows; detailed residual equations belong in [Residual Assembly](../methods/residual-assembly.md).
