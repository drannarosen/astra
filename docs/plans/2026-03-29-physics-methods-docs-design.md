# Physics + Methods Docs Expansion Design

## Goal

Turn ASTRA's current thin `Physics` and `Numerics` website sections into a durable teaching-and-development reference that explains:

- the continuous stellar-structure equations,
- the exact simplified equations ASTRA currently solves,
- the numerical methods ASTRA uses to discretize and solve them,
- and the specific ways ASTRA differs from both Stellax and MESA at the current bootstrap stage.

The target audience is mixed by design:

- future ASTRA developers,
- users trying to understand what ASTRA is actually computing,
- and students who may be new to stellar structure, Newton solves, or both.

## Design Decision

Keep the top-level website section name `Physics`, but expand it into a deeper theory-style subtree under `docs/website/physics/**`.

In parallel, replace the current loose `Numerics` bucket with a richer `Methods` subtree under `docs/website/methods/**`.

This preserves ASTRA's current site identity while creating the same conceptual split that worked well in Stellax:

- `Physics` answers "what are the equations and physical closures?"
- `Methods` answers "how does ASTRA represent, discretize, linearize, solve, and verify them?"

## Core Principle

ASTRA documentation must remain code-truthful.

Pedagogical text, equations, and explanations may be migrated from Stellax when they describe:

- continuous stellar-structure physics,
- generic constitutive ideas,
- or generic numerical reasoning.

They must be rewritten when they drift beyond ASTRA's current implementation.

The docs must never imply that ASTRA already has:

- real EOS tables,
- real opacity tables,
- real MLT,
- real abundance evolution,
- or a fully mature converged stellar structure lane.

Every substantial physics or methods page should therefore include three explicit sections:

1. `Current ASTRA implementation`
2. `Numerical realization in ASTRA`
3. `What is deferred`

## Site Architecture

### Physics subtree

Add a new landing page:

- `docs/website/physics/index.md`

Expand the section into these pages:

- `docs/website/physics/stellar-structure.md` (hub)
- `docs/website/physics/stellar-structure/mass-conservation.md`
- `docs/website/physics/stellar-structure/hydrostatic-equilibrium.md`
- `docs/website/physics/stellar-structure/energy-generation.md`
- `docs/website/physics/stellar-structure/energy-transport.md`
- `docs/website/physics/stellar-structure/coupled-problem.md`
- `docs/website/physics/eos.md` (hub)
- `docs/website/physics/eos/ideal-gas-plus-radiation.md`
- `docs/website/physics/opacity.md` (hub)
- `docs/website/physics/opacity/kramers-opacity.md`
- `docs/website/physics/nuclear.md` (hub)
- `docs/website/physics/nuclear/pp-toy-heating.md`
- `docs/website/physics/convection.md` (hub)
- `docs/website/physics/convection/radiative-gradient-and-criterion-hook.md`
- `docs/website/physics/boundary-conditions.md` (expanded existing page)

The existing top-level physics pages remain in place but become hub pages that route readers into the deeper material.

### Methods subtree

Replace the current `Numerics` section title in navigation with `Methods`, and expand the content into:

- `docs/website/methods/index.md`
- `docs/website/methods/from-equations-to-residual.md`
- `docs/website/methods/staggered-mesh-and-state-layout.md`
- `docs/website/methods/residual-assembly.md`
- `docs/website/methods/jacobian-construction.md`
- `docs/website/methods/linear-solves-and-scaling.md`
- `docs/website/methods/nonlinear-newton-and-backtracking.md`
- `docs/website/methods/initial-model-and-seeding.md`
- `docs/website/methods/boundary-condition-realization.md`
- `docs/website/methods/verification-and-jacobian-audits.md`

The current `docs/website/numerics/*.md` pages should not be deleted immediately. During migration they should either:

- be rewritten in place and moved into the new `methods/` tree, or
- remain as compatibility stubs that redirect or point to the new methods pages.

The chosen implementation should favor one canonical source page for each topic, not duplicated content.

### Dedicated MESA comparison subtree

Create:

- `docs/website/methods/mesa-reference/index.md`
- `docs/website/methods/mesa-reference/solver-scaling.md`
- `docs/website/methods/mesa-reference/boundary-conditions.md`
- `docs/website/methods/mesa-reference/mesh-and-variables.md`

These pages are not generic MESA tutorials. They are ASTRA hardening references.

Their job is to answer questions like:

- What does MESA actually solve for?
- Where does MESA scale variables or residuals?
- How does MESA place variables on the mesh?
- How are center and surface closures represented?

Every claim on these pages must be checked against the local MESA source tree:

- `/Users/anna/projects/jaxstro-dev/legacy/stellax-legacy/reference/mesa/`

## Migration Rules

### Safe to migrate from Stellax

- conceptual intros and reading maps,
- equation derivations for the classical structure equations,
- symbol definitions and physical interpretation,
- explanation of why the equations are coupled,
- explanation of why opacity/EOS/nuclear closures matter structurally,
- explanation of why solver scaling and derivative smoothness matter numerically.

### Must be rewritten for ASTRA

- any claim about production-quality tables,
- any claim about MLT or composition transport being implemented,
- any claim about autodiff/JAX-specific infrastructure,
- any claim about already-validated sensitivity pipelines,
- any claim about full convergence or solar realism.

### Must not be migrated as current ASTRA text

- real-table coverage descriptions from Stellax,
- Stellax implementation details tied to JAX, `jax.jacfwd`, GPU execution, or neural surrogates,
- production evolution-lane claims,
- anything that would make ASTRA sound more mature than the code really is.

## MESA Verification Policy

Claude notes or prior summaries are not sufficient evidence for MESA-comparison pages.

Every MESA-facing methods page must cite or at least be drafted from the local source files directly. For the initial subtree, the canonical grounding files are:

- `star/private/solver_support.f90`
- `star/private/auto_diff_support.f90`
- `star_data/public/star_data_step_input.inc`
- `star_data/public/star_data_step_work.inc`

Additional MESA files may be used when needed, but the docs should explicitly separate:

- file-backed parity,
- partial parity,
- analogy only,
- and not-yet-proven comparisons.

## Content Contract Per Page

Each major page should contain:

1. a plain-language opening for new readers,
2. the exact equation(s) or computational object,
3. symbol definitions,
4. the role of the quantity in the coupled stellar problem,
5. the exact current ASTRA implementation status,
6. links to the corresponding methods page,
7. a deferred/not-yet-implemented section,
8. and references or source grounding where relevant.

For methods pages, replace item 2 with the exact computational realization:

- unknown vector,
- residual rows,
- Jacobian split,
- scaling choice,
- update acceptance logic,
- or verification artifact, depending on page topic.

## Important Cross-Linking Rule

Every equation-level physics page should link to the methods page that realizes it in ASTRA.

Examples:

- mass conservation physics page -> residual assembly + staggered mesh methods pages
- opacity page -> energy transport physics page + Jacobian construction methods page
- boundary conditions page -> boundary-condition realization methods page

Likewise, every methods page should link back to the physics page that motivates it.

## Testing / Verification Design

This docs expansion is substantial enough that the implementation should include:

- `myst.yml` TOC updates,
- `test/test_docs_structure.jl` updates for the new canonical pages and section names,
- strict site build verification,
- and explicit checks that migrated text still contains ASTRA-truth disclaimers where required.

The docs contract test should be expanded so that it verifies the existence of:

- the new `physics/index.md`,
- the new equation-level structure pages,
- the new `methods/index.md`,
- and the new `methods/mesa-reference/` subtree.

## Scope Boundaries

This design is for documentation architecture and content only.

It does not authorize:

- new physics implementation,
- new solver packages,
- code-path hardening beyond docs-linked truth statements,
- or broad website redesign outside the `Physics`/`Methods` sections and navigation needed to support them.

## Outcome

If implemented well, ASTRA’s website will become:

- a readable introduction for new students,
- a source-of-truth for what the current code is actually solving,
- and a stable reference surface for future hardening against both ASTRA tests and local MESA source comparisons.
