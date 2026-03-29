# ASTRA Agent Guide

ASTRA is a Julia-first forward-model laboratory for stellar structure and evolution.

## Scientific contract

- ASTRA is single-star, 1D, spherically symmetric, hydrostatic, non-rotating, and non-magnetic at bootstrap.
- The canonical scientific lane is the classical baseline formulation.
- Entropy-DAE is an explicitly downstream formulation stub during bootstrap.
- The repository must not drift into mini-MESA complexity before the classical baseline is trustworthy.

## Engineering contract

- Keep the public API intentionally small.
- Keep physics, numerics, and orchestration separated.
- Use cgs `Float64` values in the solver path.
- Prefer immutable structs and type-stable parametric containers.
- Avoid abstract containers in hot paths.
- Add docstrings for all exported types and functions.

## Documentation contract

- `docs/astra-vision-spec-v1.md` is the local scope source of truth.
- The MystMD site is a first-class product: architecture memory, developer handbook, and teaching surface.
- Docs should state what is real, what is stubbed, and what is intentionally deferred.

## Testing and validation contract

- No meaningful feature lands without tests, docstrings, and a clear architectural fit.
- Early tests are allowed to be scaffold-oriented, but they should protect real invariants.
- Do not weaken tests just to make scaffolding look complete.

## Contributor expectations

- Favor readable Julia over clever abstractions.
- Keep solver ownership explicit.
- Preserve ASTRA’s forward-model identity relative to Stellax.
- Use examples and docs as onboarding tools for new Julia contributors.
