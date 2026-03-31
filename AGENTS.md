# ASTRA Agent Guide

ASTRA is a Julia-first forward-model laboratory for stellar structure and evolution.

## Scientific contract

- ASTRA is single-star, 1D, spherically symmetric, hydrostatic, non-rotating, and non-magnetic at bootstrap.
- The canonical scientific lane is the classical baseline formulation.
- Entropy-DAE is an explicitly downstream formulation stub during bootstrap.
- The repository must not drift into mini-MESA complexity before the classical baseline is trustworthy.

## Engineering contract

- Keep the public API intentionally small.
- Treat `StellarModel` with explicit `StructureState`, `CompositionState`, and `EvolutionState` blocks as the current public ownership contract.
- Keep physics, numerics, and orchestration separated.
- Use cgs `Float64` values in the solver path.
- Prefer immutable structs and type-stable parametric containers.
- Avoid abstract containers in hot paths.
- Add docstrings for all exported types and functions.

## Documentation contract

- `docs/astra-vision-spec-v1.md` is the local scope source of truth.
- The MystMD site is a first-class product: architecture memory, developer handbook, and teaching surface.
- Docs should state what is real, what is stubbed, and what is intentionally deferred.

## Communication contract

- Treat the user as the astrophysicist-in-the-loop and scientific supervisor, not as a downstream reviewer of code churn.
- For non-trivial work, default to the `explanatory-output-style` skill and explain what changed in terms of scientific ownership, numerical meaning, tradeoffs, and failure modes.
- Do not lapse into GitHub-changelog voice when the user is asking for understanding. Prefer connected prose that explains why a result matters, what it does and does not imply, and what evidence would change the conclusion.
- Distinguish clearly between code-backed facts, measured results, and hypotheses or interpretations.
- When discussing next steps, explain why a slice is small, what question it falsifies, and why broader work would or would not be overengineering.
- Tie explanations to concrete file paths, invariants, and verification, but do not let the response read like a file inventory unless the user explicitly wants that format.

## MESA reference contract

- The local MESA source mirror lives at `/Users/anna/projects/jaxstro-dev/legacy/stellax-legacy/reference/mesa/`.
- When ASTRA work depends on MESA behavior, data layout, conditioning choices, variable scaling, solver boundaries, or parity claims, read the relevant MESA source files from that local mirror first.
- Do not answer MESA-comparison questions from memory when the local source tree can resolve them.

## Docs and checklist workflow

- Treat `docs/website/**` as the canonical developer-facing documentation surface.
- Treat `docs/website/development/**` as ASTRA's operational memory lane for progress, issues, backlog, changelog, and checklists.
- Developer-facing checklists live in `docs/website/development/checklists/**`.
- The legacy `dev/checklists/**` paths are compatibility shims only; update the website-native checklist pages first.
- When a change affects accepted scope, verification status, active risks, or next-step sequencing, update the relevant `Development` page in the website in the same slice.

## Testing and validation contract

- No meaningful feature lands without tests, docstrings, and a clear architectural fit.
- Early tests are allowed to be scaffold-oriented, but they should protect real invariants.
- Do not weaken tests just to make scaffolding look complete.

## Contributor expectations

- Do not create git worktrees unless the user explicitly asks for one or approves it first; otherwise work in the current checkout.
- Favor readable Julia over clever abstractions.
- Keep solver ownership explicit.
- Preserve ASTRA’s forward-model identity relative to Stellax.
- Use examples and docs as onboarding tools for new Julia contributors.
