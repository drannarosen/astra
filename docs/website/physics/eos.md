# Equation of State

ASTRA's current EOS closure is deliberately simple: ideal gas plus radiation pressure.

## Why start here

- it is interpretable,
- it keeps the thermodynamic closure explicit,
- and it provides a clean teaching surface for later upgrades.

The important architectural change is that this placeholder closure is now exercised by the classical residual itself, not just by interface tests. Later ASTRA work can add richer EOS backends, but the rule remains the same: the solver depends on an EOS interface and helper layer rather than on one hard-coded implementation.
