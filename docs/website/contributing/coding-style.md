# Coding Style

ASTRA follows idiomatic Julia with research-code constraints:

- prefer concrete types over abstract containers,
- keep mutating `!` functions for genuine mutation,
- use explicit names with unit meaning in the identifier,
- write small readable functions instead of clever metaprogramming,
- keep the public API narrow.

For Python-native contributors, the biggest style shift is to lean on multiple dispatch and concrete callable objects instead of large inheritance trees.
