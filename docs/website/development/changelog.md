# Changelog

This page records significant ASTRA repository changes in a compact, contributor-facing form.

## 2026-03-30

### Added

- a canonical Physics page for the Eddington-grey atmosphere and photosphere staging
- a Phase 2 one-sided `T(\tau)` atmosphere closure for the classical outer boundary
- explicit weighted residual and correction metrics for the classical Newton controller
- weighted residual and correction histories in solve diagnostics
- a canonical Methods page for nonlinear step metrics and the future merit-based globalization direction
- a progress-history fix so the stored weighted residual metric matches the frozen acceptance metric

### Changed

- the surface temperature and pressure rows now use atmosphere-derived targets instead of guessed outer thermodynamic values
- the surface thermodynamic rows use the shared outer match-point helper layer
- the surface pressure scale uses the shared outer match-point pressure scale
- the outer transport row remains one-sided to the photospheric face
- solver row weights now treat the atmosphere surface rows in temperature and pressure units rather than the old density guess
- trial steps are now limited by weighted correction RMS and max-correction envelopes before backtracking
- nonlinear acceptance now requires weighted residual improvement plus a raw-residual safeguard
- the handbook now distinguishes solver metrics from physical residual meaning more explicitly
- the atmosphere boundary is now documented as a Phase 2 one-sided `T(\tau)` closure rather than a guessed density closure

### Notes

The current controller is stronger and more transparent than the older raw-norm-only slice, but it is still not a full merit-function or trust-region globalization scheme. The weighting policy remains part of the current bootstrap numerical contract rather than a proven final design. The atmosphere boundary is now a staged one-sided `T(\tau)` reconstruction with the surface thermodynamic rows using the shared outer match-point helper layer and the outer transport row remaining one-sided to the photospheric face, not yet a full tabulated atmosphere module.

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
