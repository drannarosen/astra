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

### Notes

The current solver is still a bootstrap Newton solve against an analytic reference-profile residual. This change improves ownership clarity and verification discipline, not the underlying stellar-physics fidelity.
