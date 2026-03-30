# MESA Reference

This subtree records source-backed comparison notes against the local MESA mirror.

## Label system

Each claim in this subtree is labeled so we do not blur evidence levels:

- `file-backed parity` means the behavior is visible directly in the named MESA file and ASTRA matches the same owner or pattern closely.
- `partial parity` means ASTRA matches the high-level idea, but not the full implementation detail in MESA.
- `analogy only` means the comparison is pedagogical, not a claim of implementation equivalence.
- `not yet proven` means the MESA source suggests a useful direction, but ASTRA has not yet reproduced it or the source evidence is incomplete for a stronger claim.

The scope is intentionally narrow: solver scaling, boundary conditions, and variable layout that we can verify directly in the local source tree. Anything else stays out of this subtree until the source evidence is strong enough.
