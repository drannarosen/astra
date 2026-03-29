# Stellar Structure

The classical 1D stellar-structure problem is built from four coupled ideas:

- mass continuity,
- hydrostatic equilibrium,
- energy conservation,
- energy transport.

ASTRA's long-term classical baseline will turn those into a coupled nonlinear solve in the enclosed-mass coordinate.

## Bootstrap status

The current repository does not yet implement the full classical residual. Instead, it scaffolds the state topology and numerical interfaces that the classical residual will later inhabit.

That distinction is important: the current code teaches the architecture of a stellar solve without overclaiming the physics maturity.
