# Formulation Interface

ASTRA treats the framework and the method as separate ideas.

- The **framework** owns package structure, state representation, validation philosophy, and workflow.
- A **formulation** owns how the governing equations are written and solved.

## Bootstrap policy

- `ClassicalHenyeyFormulation` is the canonical lane.
- `EntropyDAEFormulation` exists only as a documented stub.

That policy matters scientifically. ASTRA should become the place where formulations are compared, not a codebase whose identity is captured by whichever experimental method arrived first.
