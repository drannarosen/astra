# Diagnostics

Diagnostics are where ASTRA reports what a solve did, not what we wish it had done.

At bootstrap, the diagnostics object tracks:

- residual norm,
- convergence status,
- iteration count,
- one central thermodynamic summary,
- surface luminosity,
- formulation label,
- and explicit notes explaining the toy nature of the solve.

That note field is intentional: scientific software should preserve what a result does **not** prove, not only what it prints.
