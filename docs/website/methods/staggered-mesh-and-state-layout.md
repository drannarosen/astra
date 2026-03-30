# Staggered Mesh and State Layout

ASTRA uses a staggered mesh so geometric quantities live on faces and thermodynamic state lives in cells. That gives the classical residual a clean ownership split and keeps the packed state close to the physics.

## Face-centered and cell-centered ownership

The solve-owned structure state is:

- face-centered `log(radius_face_cm)`,
- face-centered `luminosity_face_erg_s`,
- cell-centered `log(temperature_cell_k)`,
- cell-centered `log(density_cell_g_cm3)`.

That face/cell split is the core of the layout. Radius and luminosity naturally live on faces because they are boundary flux or geometry quantities. Temperature and density live at cell centers because they are local thermodynamic state.

## Packed state

`pack_state(state)` concatenates those four blocks into one packed state vector, and `unpack_state(template, values)` reverses the process. The packed state is the object Newton sees; the structured `StellarModel` is the object the rest of ASTRA reasons about.

## Why this layout exists

The staggered layout keeps the residual rows local: geometry couples adjacent faces and a cell density, hydrostatic balance uses adjacent cell pressures and one face radius, luminosity uses one cell source term, and transport uses adjacent cell temperatures and pressures. That locality is what makes the Jacobian block structure readable.

For the physics-side interpretation of those owners, see [Physics: Stellar Structure](../physics/stellar-structure.md). For the closest source-backed MESA comparison on variable staggering and `i_lum`, see [MESA Reference: Mesh and Variables](mesa-reference/mesh-and-variables.md).

For the continuous structure equations that motivate this ownership split, see [Stellar Structure](../physics/stellar-structure.md). For the closest source-backed MESA comparison on variable staggering and solve-owned arrays, see [MESA Reference: Mesh and Variables](mesa-reference/mesh-and-variables.md).

## Implementation checklist

- [x] Face-centered and cell-centered ownership is stated explicitly.
- [x] `pack_state` and `unpack_state` are identified as the code-level realization of the contract.
- [ ] The page should eventually include a small stencil diagram showing which row family touches which neighboring state entries.
