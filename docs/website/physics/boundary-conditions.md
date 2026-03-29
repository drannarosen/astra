# Boundary Conditions

Boundary conditions are not side details in a stellar code. They are part of the model definition.

At bootstrap, ASTRA uses reference-profile boundary rows to make boundary ownership explicit:

- center constraints on the innermost face variables,
- surface constraints on the outermost face and cell variables.

Later, these rows should be replaced by physically motivated center and surface closures for the classical baseline solve.
