# Verification and Jacobian Audits

This page collects the checks that keep ASTRA honest while the classical lane is still being hardened.

The key pedagogical idea is that ASTRA's verification surfaces should mirror ASTRA's ownership surfaces. If a page makes a claim about derivatives, there should be a derivative-oriented check. If a page makes a claim about solver progress, there should be a solve-oriented artifact. Verification is most useful when it answers the same question the design is trying to answer.

## Local derivative validation

This local derivative validation checks the EOS, opacity, nuclear, and transport helper derivatives against finite differences so we know the sensitivities are behaving before we trust the Jacobian.

## Block jacobian

`test_block_jacobian.jl` exercises the structured Jacobian path, and `jacobian_fidelity_audit` compares row families against row-local finite differences. That block jacobian audit tells us whether an analytic row really improved the solve.

## Default newton progress

`test_default_newton_progress.jl` and `scripts/run_examples.jl` check the public solve path. The current default newton progress evidence is the 24-cell demo with `8` accepted steps, `289` rejected trials, and a residual drop from `2.1962008371612166e22` to `1.1903032914682583e19`.

The physics-side reason this matters is the coupled solve described in [Physics: The Coupled Problem](../physics/stellar-structure/coupled-problem.md): a Jacobian improvement is only meaningful if the full boundary-value problem actually takes better Newton steps.

## Why this matters

Verification is not a side effect. It is the method by which we distinguish a solver improvement from a better-looking failure.

## Verification checklist

- [x] Local derivative validation is identified.
- [x] Block Jacobian validation is identified.
- [x] Public Newton-progress evidence is identified.
- [ ] Durable benchmark artifacts should be linked here once ASTRA starts storing them systematically.

## Open-risk checklist

- [x] Current Newton progress is still non-converged.
- [ ] The verification surface still needs equation-family and benchmark-level artifacts before it can support stronger physical claims.
