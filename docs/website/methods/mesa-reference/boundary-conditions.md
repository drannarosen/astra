# Boundary Conditions in MESA

The relevant MESA evidence is in `star/private/auto_diff_support.f90` and `star_data/public/star_data_step_input.inc`.

## file-backed parity

`star_data_step_input.inc` shows that MESA stores `R_center` and `L_center` as inner-boundary inputs, with both described as values at the inner edge of the innermost cell.

`auto_diff_support.f90` shows that the boundary wrapping for luminosity and radius treats the center values as the special inner-edge quantities used by the solver. In particular, `wrap_L_p1` falls back to `s% L_center`, while `wrap_r_p1` falls back to `s% r_center`, the working-state radius counterpart of the input-side `R_center` name.

## partial parity

ASTRA's center asymptotic closure follows the same basic idea that the center is a special boundary that should not be treated like a regular interior stencil. That is partial parity, because ASTRA currently uses a simpler bootstrap realization rather than MESA's full AD-aware wrapping pattern.

## analogy only

The outer surface closure in ASTRA is only analogy only relative to the MESA source we inspected here. The local files above do not justify a claim that ASTRA has MESA's full surface handling or atmosphere treatment.

## not yet proven

We have not yet matched MESA's full center/surface ownership semantics across all boundary-related variables, nor have we shown that ASTRA reproduces MESA's exact solver behavior when those center values are updated during a full step.
