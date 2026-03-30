# Initial Model and Seeding

ASTRA's bootstrap model is geometry-consistent, source-matched, and surface-anchored.

## Geometry-consistent

The initial radius profile is built from the mass grid and the target radius guess so the shell volumes are self-consistent from the start. Density is then inferred from the resulting geometry rather than guessed independently.

## Source-matched

The temperature profile is adjusted so the initial luminosity roughly matches the integrated toy nuclear source. That gives the luminosity row a sensible starting point instead of forcing Newton to discover the entire energy scale from nothing.

## Surface-anchored

The outer temperature and density are anchored to the declared surface guesses. That keeps the first residual evaluation in the right numerical neighborhood while still leaving the solve free to move.

## Why this matters

This is a bootstrap seed, not a calibrated stellar model. The goal is to reduce the chance that the first Newton step is dominated by bad geometry or wildly inconsistent source terms.
