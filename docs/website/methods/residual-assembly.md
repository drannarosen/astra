# Residual Assembly

ASTRA assembles the residual vector in physical order, not in whatever order happens to be convenient for a matrix buffer.

## Row ordering

The current residual has three top-level groups:

- center rows,
- interior blocks,
- surface rows.

The center rows enforce the asymptotic inner radius and luminosity targets. Each interior block then contributes four rows:

1. geometry,
2. hydrostatic balance,
3. luminosity balance,
4. transport.

The surface rows enforce the provisional outer closure.

## What each interior block means

The row family mirrors the current `src/residuals.jl` implementation:

- geometry compares shell volume to `dm / rho`,
- hydrostatic balance compares adjacent-cell pressure plus gravity,
- luminosity balance subtracts `dm * eps_nuc`,
- transport uses the log-form radiative gradient row.

That means the residual is already source-decomposed in the energy equation, but only in the bootstrap sense. The current closure stack is still toy physics; the row order is what matters here.

## Why this page exists

This is the canonical map from equation language to the discrete solve. If a future developer wants to know which residual row owns a bug, this page should answer the question before they start reading code.
