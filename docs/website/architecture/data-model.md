# Data Model

ASTRA's data model is built from small, explicit Julia structs. A **struct** is just a named container with well-defined fields. In ASTRA, these containers are not only for storing numbers. They are used to make ownership visible.

The big architectural job of the data model is to turn different roles in the code into explicit objects. Setup, model state, execution, and closure layers are represented by different object families on purpose.

## The main object families

The current code centers on a few object families:

- scalar setup objects such as `Composition`, `StellarParameters`, `GridConfig`, and `SolverConfig`, which define a calculation before a solve starts,
- persistent model-state objects such as `StructureState`, `CompositionState`, `EvolutionState`, and `StellarModel`, which store the star itself,
- execution objects such as `StructureProblem`, `SolveResult`, and `StructureDiagnostics`, which represent one solve and its outputs,
- and the closure bundle `MicrophysicsBundle`, which carries the local physics rules used by the solve.

For one concrete example: `StellarModel` is the star being carried through the code, `StructureProblem` is the solve being posed, and `SolveResult` is what comes back after ASTRA tries to solve it.

That list describes the current code, not a speculative future architecture.

## Transitional implementation versus canonical architecture

The important public split is now explicit in code: `StructureState`, `CompositionState`, and `EvolutionState` are bundled by `StellarModel`.

An internal `StellarState` helper still exists only as transitional legacy scaffolding. When you are learning ASTRA's architecture, treat the explicit three-block `StellarModel` split as canonical.

## Why immutable structs help

If you are new to Julia, one useful idea is that many ASTRA objects are **immutable structs**. That means the high-level container itself is not casually rewritten in place. In architectural terms, that helps keep the model's shape and ownership stable and reduces accidental side effects.

## Why parametric bundles help

`MicrophysicsBundle{E,O,N,C}` is a good example of Julia's type system helping architecture. A **parametric** struct is one whose field types are known in advance. Here that means ASTRA can carry concrete EOS, opacity, nuclear, and convection callables without falling back to vague abstract containers in hot code paths.

That matters for beginners too: Julia can optimize this bundle more effectively, and ASTRA avoids vague "anything goes" containers in hot code paths.

For contributors, the practical lesson is simple: the bundle is not fancy syntax for its own sake. It is how ASTRA keeps the closure layer explicit, fast, and inspectable.

## The ownership lesson

The main takeaway of this page is that the data model should make it obvious which quantities are:

- persistent model state,
- solve-owned unknowns,
- evolution-owned metadata,
- or derived closures.

If a type definition makes those roles harder to see, it is working against ASTRA's architecture even if it is technically convenient.

## Data-model checklist

- [x] The page explains what a struct is in ASTRA's own context.
- [x] The page groups the main exported types by architectural role.
- [x] The canonical `StellarModel` split is identified as current public architecture.
- [x] The page explains immutable and parametric structs in plain language before using them architecturally.
- [x] The closing lesson ties the type system back to ownership rather than to style alone.
