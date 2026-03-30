# Boundary Conditions in MESA

The relevant MESA evidence for the current ASTRA comparison is in:

- `star_data/public/star_data_step_input.inc`
- `star/private/auto_diff_support.f90`

## file-backed parity

`star_data_step_input.inc` shows that MESA stores `R_center` and `L_center` as inner-boundary inputs, with both described as values at the inner edge of the innermost cell.

`auto_diff_support.f90` shows that the AD-aware boundary wrapping for luminosity and radius treats center values as special stored boundary quantities rather than as ordinary interior neighbors. In particular, `wrap_L_p1` falls back to `s% L_center`, while `wrap_r_p1` falls back to `s% r_center`.

That is the source-backed reason ASTRA treats MESA as a reference surface for explicit center-boundary ownership: the center is represented separately in the solver machinery, not silently folded into an interior stencil.

## partial parity

ASTRA's center asymptotic closure follows the same basic idea that the center is a special boundary that should not be treated like a regular interior stencil. That is partial parity, because ASTRA currently uses a simpler bootstrap realization rather than MESA's full AD-aware wrapping pattern.

## analogy only

The outer surface closure in ASTRA is only analogy only relative to the MESA source we inspected here. The local files above do not justify a claim that ASTRA has MESA's full surface handling or atmosphere treatment.

## not yet proven

We have not yet matched MESA's full center/surface ownership semantics across all boundary-related variables, nor have we shown that ASTRA reproduces MESA's exact solver behavior when those center values are updated during a full step.

## MESA parity checklist

- [x] Center-value storage claims are tied to `star_data_step_input.inc`.
- [x] Special center-boundary wrapping claims are tied to `auto_diff_support.f90`.
- [ ] ASTRA does not yet have source-backed surface-boundary parity claims against MESA.
