# Formulation Interface

ASTRA treats the framework and the method as separate ideas.

- The **framework** owns package structure, state representation, validation philosophy, and workflow.
- A **formulation** owns how the governing equations are written and solved.

## Bootstrap policy

- `ClassicalHenyeyFormulation` is the canonical lane.
- `EntropyDAEFormulation` exists only as a documented stub.

That policy matters scientifically. ASTRA should become the place where formulations are compared, not a codebase whose identity is captured by whichever experimental method arrived first.

## Implication for differentiability

This formulation policy is also ASTRA's correct differentiability order.

The classical formulation should own the first serious solver and the first serious derivative boundary, because it gives ASTRA:

- an interpretable residual operator,
- an interpretable Jacobian,
- a clear solve-owned state,
- and a baseline against which later formulation-specific sensitivity methods can be judged.

Entropy-DAE should therefore arrive later as a sibling frontend over the same operator core. It should not become a shortcut around unresolved baseline questions in the classical lane.
