# Milestones

Read these milestones as architecture checkpoints, not release-marketing labels. A milestone matters in ASTRA only if it changes what the code can honestly claim to own or validate.

## Milestone 0

- package scaffold
- docs scaffold
- tests and examples
- CI-ready workflow

## Milestone 1

- types, config, grid, and state architecture
- toy microphysics interfaces
- toy residual and Jacobian path

## Milestone 2

- state/model ownership refactor
- contract-aware tests
- explicit residual ordering and solve-owned structure block

## Milestone 3

- classical baseline structure solver
- EOS and opacity closures serving a real hydrostatic residual
- baseline MLT-based convection closure

## Milestone 4

- initialization lane: low-mass PMS seed plus relaxation
- minimal evolution with gravothermal bookkeeping
- ZAMS detection by energy partition

## Milestone 5

- solar-age compact target-vector validation
- later, Entropy-DAE experimental formulation and comparison framework
