# MESA Reference

This subtree records source-backed comparison notes against the local MESA mirror.

The purpose of this subtree is discipline, not prestige. MESA is the numerics reference surface ASTRA compares against most often, but that comparison is only useful if it is honest about evidence. These pages therefore describe only what we have actually checked in the local source tree at `/Users/anna/projects/jaxstro-dev/legacy/stellax-legacy/reference/mesa/`.

## Label system

Each claim in this subtree is labeled so we do not blur evidence levels:

- `file-backed parity` means the behavior is visible directly in the named MESA file and ASTRA matches the same owner or pattern closely.
- `partial parity` means ASTRA matches the high-level idea, but not the full implementation detail in MESA.
- `analogy only` means the comparison is pedagogical, not a claim of implementation equivalence.
- `not yet proven` means the MESA source suggests a useful direction, but ASTRA has not yet reproduced it or the source evidence is incomplete for a stronger claim.

The scope is intentionally narrow: solver scaling, boundary conditions, and variable layout that we can verify directly in the local source tree. Anything else stays out of this subtree until the source evidence is strong enough.

## Usage checklist

- [x] Every claim in this subtree must be labeled with one of the four evidence levels.
- [x] Every parity claim must name the local MESA source file or files.
- [ ] Every page in this subtree should end with a checklist showing what has and has not been proven for ASTRA relative to MESA.
