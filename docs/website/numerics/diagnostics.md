# Diagnostics

Canonical guide: [Verification and Jacobian Audits](../methods/verification-and-jacobian-audits.md).

Diagnostics are where ASTRA reports what a solve did, not what we wish it had done.

The canonical hardening and verification narrative now lives in [Methods: Verification and Jacobian Audits](../methods/verification-and-jacobian-audits.md). This page remains as a shorter note about what the diagnostics object reports.

At bootstrap, the diagnostics object tracks:

- residual norm,
- merit history,
- initial and final row-family merit summaries,
- convergence status,
- iteration count,
- one central thermodynamic summary,
- surface luminosity,
- formulation label,
- and explicit notes explaining the toy nature of the solve.

That note field is intentional: scientific software should preserve what a result does **not** prove, not only what it prints.

The current row-family surface is still intentionally small. The diagnostics object reports initial and final row-family merit summaries, not full rejected-trial attribution and not predicted-versus-actual decrease accounting.

## Pedagogical point

Diagnostics are part of the teaching surface of ASTRA. A contributor should be able to inspect a solve result and learn both:

- what the code measured,
- and what conclusions would still be scientifically premature.

## Summary checklist

- [x] This page explicitly points back to the canonical numerical specification in `Methods`.
- [x] The page treats diagnostics as evidence and limitation reporting, not marketing.
- [ ] Keep detailed verification policy in [Verification and Jacobian Audits](../methods/verification-and-jacobian-audits.md).
