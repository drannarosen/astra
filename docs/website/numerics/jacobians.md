# Jacobians

The bootstrap Jacobian is computed with finite differences. That is not the intended long-term endpoint, but it is the right first step for a new Julia codebase because it makes the solver contract visible with very little hidden machinery.

Later ASTRA work can compare:

- finite-difference Jacobians,
- hand-assembled structured Jacobians,
- and automatic-differentiation-backed Jacobians,

provided those options stay behind a stable solver interface.
