# Adding a Microphysics Module

Adding new physics to ASTRA should start with the interface, not with solver surgery.

## Bootstrap pattern

1. Define a new concrete callable type in `src/microphysics/`.
2. Make it return a small, explicit result object or named tuple.
3. Add tests for the physical contract you expect from that module.
4. Wire it into a `MicrophysicsBundle`.
5. Only then update the solver-facing code if new closure information is genuinely required.

This is one of the main Julia lessons in ASTRA: use concrete callable objects and dispatch to keep the interfaces explicit without forcing class hierarchies.
