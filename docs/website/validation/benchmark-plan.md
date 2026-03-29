# Benchmark Plan

ASTRA's benchmark program should grow in layers.

That layered approach matters because a fast answer is not useful if it is attached to an untrusted scientific slice. Benchmarks should therefore track the maturity of the architecture, not just raw runtime.

## Near-term

- bootstrap solve runtime,
- allocation counts for residual and Jacobian paths,
- toy problem scaling with cell count,
- state/model refactor regression checks.

## Mid-term

- classical baseline solve performance,
- relaxation-stage convergence behavior,
- PMS timestep behavior and acceptance statistics,
- structured linear-solver comparisons,
- convergence behavior under formulation changes.

## Long-term

- compact solar-age benchmark regression,
- reference comparisons against trusted external solutions,
- method-comparison experiments between classical baseline and Entropy-DAE.
