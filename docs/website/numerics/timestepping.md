# Timestepping

Time-dependent evolution is explicitly downstream of the classical baseline.

The `evolution/` module is still present at bootstrap because ASTRA wants to reserve the architectural slot now:

- timestep type,
- controller abstraction,
- update entry point.

The current `step_evolution!` function exists to state that evolution is not implemented yet, not to pretend that it is.
