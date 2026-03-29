# Equation of State

The bootstrap EOS is deliberately simple: ideal gas plus radiation pressure.

## Why start here

- it is interpretable,
- it keeps the thermodynamic closure explicit,
- and it provides a clean teaching surface for later upgrades.

Later ASTRA work can add richer EOS backends, but the initial rule is that the solver must depend on the EOS interface rather than on one hard-coded implementation.
