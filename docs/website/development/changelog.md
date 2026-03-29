# Changelog

This page records significant ASTRA repository changes in a compact, contributor-facing form.

## 2026-03-29

### Added

- explicit `StructureState`, `CompositionState`, `EvolutionState`, and `StellarModel` types to the public API
- contract-aware tests for model ownership and solve behavior
- a `Development` documentation lane for progress tracking, backlog, and issue visibility

### Changed

- the solve vector is now restricted to the structure block
- nonlinear solves and diagnostics now operate on `StellarModel`
- examples and onboarding docs now teach the explicit ownership contract rather than the old flat-state story
- the first classical residual slice replaced the analytic reference-profile interior rows with geometric, hydrostatic, luminosity, and transport equations
- boundary rows now use minimal physical center/surface closures, while the surface closure remains provisional
- the website now documents ASTRA's differentiability strategy in terms of explicit solver boundaries, implicit differentiation, and a classical-first Julia roadmap

### Notes

The current solver now evaluates a real classical residual with placeholder closures. This improves physical equation ownership and verification discipline, but it does not yet deliver validated solar fidelity or a robust convergence basin from the default initialization.
