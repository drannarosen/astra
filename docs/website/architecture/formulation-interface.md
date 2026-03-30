# Formulation Interface

ASTRA treats the **framework** and the **formulation** as separate ideas. The framework owns the package structure, state representation, validation strategy, and contributor workflow. A formulation owns how the governing equations are written and solved.

That separation is important because ASTRA is not supposed to become "the codebase for whichever method arrived first." It is supposed to be the place where methods can be implemented, compared, and judged against a clear baseline.

## What interface means here

An **interface** is the boundary a component presents to the rest of the code. For formulations, that means ASTRA needs a clean way to say which mathematical lane is active without rewriting the whole package around it.

In practice, a contributor should be able to add or compare a formulation without rewriting ASTRA's package layout, state model, or validation ladder.

In the current code, that surface is represented by `AbstractFormulation` with concrete lanes such as `ClassicalHenyeyFormulation` and `EntropyDAEFormulation`.

## Bootstrap policy

The current formulation policy is intentionally strict:

- `ClassicalHenyeyFormulation` is the canonical lane.
- `EntropyDAEFormulation` exists only as a documented stub.

That is not a matter of taste. It is a scientific sequencing decision. ASTRA should first earn a trustworthy classical baseline before asking contributors to compare more experimental formulations against it.

## What a formulation should own

A formulation should own the mathematical writing of the problem: which variables are primary, how the governing equations are arranged, what residual system is solved, and what derivative boundary makes sense for that lane.

For example, one formulation may choose a different primary variable set or residual arrangement while still living inside ASTRA's shared package, state, and validation structure.

A formulation should **not** own the whole framework. It should not redefine the package layout, hide the state-ownership model, or bypass the validation ladder just because it is numerically interesting.

## Implication for differentiability

This formulation policy is also ASTRA's differentiability order.

The classical formulation should own the first serious solve boundary and the first serious derivative boundary because it gives ASTRA an interpretable residual operator, an interpretable Jacobian, a clear solve-owned state, and a baseline against which later formulation-specific sensitivity methods can be judged.

Entropy-DAE should therefore arrive later as a sibling frontend over the same operator core. It should not become a shortcut around unresolved classical-baseline physics, solver, or validation questions.

## Formulation QA and open checks

### Conceptual architecture

- [x] Framework responsibilities are separated from formulation responsibilities.
- [x] The word interface is defined in ASTRA's own architectural language.
- [x] The canonical-lane policy is stated clearly.
- [x] The page explains what a formulation should own and what it should not own.
- [x] The differentiability order follows the same canonical-lane sequencing.

### Current implementation status

- [x] `AbstractFormulation` exists as the framework-level formulation surface in code.
- [x] `ClassicalHenyeyFormulation` exists as the implemented canonical lane type.
- [x] `EntropyDAEFormulation` exists only as a bootstrap placeholder lane.
- [ ] Shared operator-core assumptions are already enforced strongly enough in code to support multiple mature sibling formulations cleanly.
- [ ] Formulation-specific API boundaries are stable enough for routine extension without architectural risk.

### Validation and comparison status

- [ ] The classical lane is validated strongly enough to serve as a trustworthy comparison baseline for future formulations.
- [ ] Formulation-level residual comparisons exist across sibling lanes.
- [ ] Formulation-level solver diagnostics are comparable across lanes.
- [ ] Shared validation criteria are defined for future sibling formulations.
- [ ] Differentiability comparisons across formulations have been tested.

### Open risks / next checks

- [ ] The shared operator core is stable enough to support multiple formulations without leaking lane-specific assumptions.
- [ ] Future formulations are prevented from bypassing ownership contracts in the framework or state model.
- [ ] Formulation-specific state choices remain compatible with ASTRA's public data model.
- [ ] Validation ladders are strong enough before additional formulation lanes are expanded.
- [ ] Differentiability semantics remain formulation-specific while still staying framework-consistent.
