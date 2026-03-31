# Initial Model and Seeding

ASTRA's bootstrap model is geometry-consistent, source-matched, and surface-anchored.

The current public default is still the geometry-consistent `bootstrap_default`
lane. A second internal seed family, `convective_pms_like`, is now available
for diagnostic-only convergence-basin audits. It is intentionally not the
canonical startup path, and it is intentionally not exposed as a public seed
selection API in this slice.

## Geometry-consistent

The initial radius profile is built from the mass grid and the target radius guess so the shell volumes are self-consistent from the start. Density is then inferred from the resulting geometry rather than guessed independently.

## Source-matched

The temperature profile is adjusted so the initial luminosity roughly matches the integrated toy nuclear source. That gives the luminosity row a sensible starting point instead of forcing Newton to discover the entire energy scale from nothing.

## Surface-anchored

The outer temperature and density are anchored to the declared surface guesses. That keeps the first residual evaluation in the right numerical neighborhood while still leaving the solve free to move.

## Why this matters

This is a bootstrap seed, not a calibrated stellar model. The goal is to reduce the chance that the first Newton step is dominated by bad geometry or wildly inconsistent source terms.

## Diagnostic-only PMS-like lane

The internal `convective_pms_like` seed reuses ASTRA's current grid and outer
surface family definition, keeps uniform composition, lowers the central
temperature target, uses a near-adiabatic thermodynamic shape, and replaces the
source-matched luminosity profile with a contraction-powered luminosity scale.

This lane exists only to test whether seed family materially changes ASTRA's
current convergence basin. It does not yet claim a canonical PMS startup, and
it does not replace the longer-term architecture target of PMS seed ->
relaxation -> PMS evolution -> ZAMS detection.

## What ASTRA is not doing here

ASTRA is not promoting `convective_pms_like` to the public default from one
diagnostic slice, and ASTRA is not treating a saved ZAMS import as the
canonical seed strategy. Saved ZAMS remains deferred as a later control lane
for benchmarking and solver comparison rather than as the science-lane startup
owner.
