# ASTRA

**ASTRA** is the **Adaptive STellar Research Architecture**: a Julia-first framework for stellar structure and evolution built around clarity, validation readiness, and controlled method development.

This site has four jobs at once:

- orient new contributors,
- explain the architecture and scientific scope,
- preserve design memory,
- and teach the physics and numerics behind the code.

## What ASTRA is for

ASTRA is a forward-model laboratory. Its first responsibility is to support a clean classical stellar-structure lane that can later serve as the comparison surface for more experimental ideas, including Entropy-DAE.

ASTRA is intentionally **not** a MESA clone, not a giant physics warehouse, and not a rushed attempt to implement all of stellar evolution in one pass.

## How ASTRA differs from Stellax

- **Stellax** is the flagship differentiable framework where inference and gradients are central.
- **ASTRA** is the Julia-first code where solver ownership, formulation clarity, and validation discipline come first.

That makes ASTRA a companion code and a reference engine, not a replacement.

## How to use this site

- Start with [Getting Started](getting-started/installation.md) if you want to install Julia, run the scaffold, and inspect the package layout.
- Read [Architecture](architecture/overview.md) if you want to understand how ASTRA separates physics, numerics, and orchestration.
- Read [Validation](validation/philosophy.md) if you want to know what the current scaffold proves and what it does not.
- Read [Planning](planning/roadmap.md) if you want the scientific sequence from bootstrap to classical baseline and later method-comparison work.
- Read [Development](development/development-guide.md) if you want to know what changed recently, what is blocked, and what is queued next.

If you are new to the repo, read the site in that order. ASTRA's docs are meant to teach how to think about the codebase, not just where the files live.

## Current status

The current repository is a bootstrap milestone:

- package scaffold,
- toy structure residual/Jacobian path,
- tests and examples,
- MystMD handbook,
- formulation scaffolding,
- explicit documentation of what is stubbed.

The classical baseline solver is the next serious scientific milestone.
