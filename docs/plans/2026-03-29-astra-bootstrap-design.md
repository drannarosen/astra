# ASTRA Bootstrap Design Note

> This note records the architectural intent behind the initial ASTRA repository scaffold.

## Goal

Bootstrap ASTRA as a Julia-first forward-model laboratory with a small public API, a pedagogical handbook site, and a solver architecture that can grow into a trustworthy classical baseline before adding more ambitious formulations.

## Key decisions

- One root Julia package, not a multi-package workspace.
- Latest stable Julia target.
- BSD-3-Clause license.
- Committed root environment intended once Julia is available locally.
- cgs `Float64` values rather than runtime unit types in the hot path.
- Classical baseline as canonical lane.
- Entropy-DAE present as a documented stub only.

## Bootstrap solver policy

The current residual/Jacobian path is an analytic reference-profile problem. This is intentional. It gives ASTRA a real numerical interface without overstating the scientific maturity of the repository.

## Immediate next steps

1. Install Julia in the development environment and generate the root `Manifest.toml`.
2. Run the bootstrap tests and examples.
3. Replace the toy residual with the first physically meaningful classical structure residual.
4. Expand diagnostics and validation around that classical lane before touching evolution.
