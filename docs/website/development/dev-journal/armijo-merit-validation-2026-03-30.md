# Armijo Merit Validation Evidence

This note records the current Armijo merit validation sweep as a dated artifact-backed snapshot.

Retention status: `historical`

Exact command used:

```bash
~/.juliaup/bin/julia --project=. scripts/run_armijo_merit_validation.jl artifacts/validation/2026-03-30-armijo-merit-validation
```

Artifact directory:

`artifacts/validation/2026-03-30-armijo-merit-validation`

## Run matrix

The bundle covers the current classical lane on a 5-point cell-count ladder plus the default fixture and a deterministic perturbation family:

- `cells-6`
- `cells-8`
- `cells-12`
- `cells-16`
- `cells-24`
- `default-12`
- `perturb-a1e-6-case-01`
- `perturb-a1e-6-case-02`
- `perturb-a1e-6-case-03`

All nine payloads in the dated bundle report `converged = false`.

## Measured Results

- accepted step count: `8` for every payload in the bundle.
- rejected trial count: `412` to `1052` across the bundle, with `default-12 = 540`.
- Representative rho behavior: `rho` is the accepted-step decrease ratio; for `default-12` it begins near unity and falls to `0.4223152808592588` by the last accepted step. The `cells-6` case falls to `0.4054457252100213`, and `perturb-a1e-6-case-03` falls to `0.48825615007102174`.
- Dominant accepted families: `transport` in all `9/9` payloads.
- Dominant best-rejected families: `transport` in all `9/9` payloads.
- best rejected trial: the dominant family is `transport` in all `9/9` payloads.
- Regularization-usage frequency: `used_regularized_fallback = true` in all `9/9` payloads.

## Interpretation

The evidence points to a mixed picture.

Conditioning is still a real problem: every payload needed the regularized fallback path, and the rejected-trial counts are large across the entire matrix. That tells us the current linearized model is still fragile.

row-family-local trouble is the sharper repeated signature. The accepted-step dominant family and the best-rejected dominant family are both `transport` in every payload, and the late-step rho degradation also shows up in the same family-dominated cases. That pattern is more specific than a generic conditioning complaint, so the current bundle points more strongly toward transport-row or outer-boundary hardening than toward a purely global conditioning fix.

What this evidence does not prove:

- it does not isolate whether the transport trouble is caused by surface closure, atmosphere semantics, or correction scaling,
- it does not prove that adaptive regularization alone would cure the basin,
- and it does not establish robust convergence beyond this current classical fixture family.

## Recommendation

Row-family-local hardening next.

The transport family is the stable recurring signature across the entire bundle, including the accepted steps and the best rejected trials. Regularization is already being used everywhere, so the next most informative move is to harden the transport/outer-boundary row family rather than to assume generic adaptive regularization will solve the narrow basin on its own.
