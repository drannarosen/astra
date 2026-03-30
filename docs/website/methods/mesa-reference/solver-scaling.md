# Solver Scaling in MESA

The comparison here is source-backed, not aspirational. The key local MESA files are:

- `star_data/public/star_data_step_work.inc`
- `star/private/solver_support.f90`
- `star/private/star_solver.f90`
- `star/private/star_utils.f90`

## file-backed parity

`star_data_step_work.inc` declares solver work arrays `x_scale`, `residual_weight`, and `correction_weight`. That is the first file-backed sign that MESA treats conditioning as explicit solver state rather than as an invisible implementation detail.

In `set_xscale_info` inside `solver_support.f90`, MESA assigns per-variable scaling factors through `s% x_scale(i,k)`. The logic distinguishes structure variables from abundance variables and, for ordinary structure variables, scales by the magnitude of the current starting state `abs(s% xh_start(i,k))` with a floor.

In `eval_equations` inside `solver_support.f90`, MESA resets `s% residual_weight(j,k)` and `s% correction_weight(j,k)` before evaluating equations, then later in the same file assigns variable-specific `correction_weight` entries such as the luminosity weight `1d0/(frac*s% L_start(1) + abs(s% L(k)))`.

In `star_solver.f90`, MESA computes `correction_norm` and `max_abs_correction` using those scaled corrections and then limits the applied correction using `scale_correction_norm` and `scale_max_correction`.

That combination is the file-backed pattern ASTRA is using as a reference surface: explicit variable scaling, explicit correction weighting, and explicit correction-size limits.

## partial parity

ASTRA shares the same high-level goal: keep luminosity in physical `erg/s` and scale the solve numerically rather than redefining the physics variable. That is partial parity, because ASTRA's scaling is much simpler and does not reproduce MESA's full per-variable machinery.

## analogy only

Any claim that ASTRA has MESA's complete correction-limit behavior would be analogy only at this stage. The local source clearly shows additional MESA logic around retry handling and variable-specific safeguards that ASTRA does not yet mirror.

## not yet proven

We have not yet shown that ASTRA's scaling choices reproduce MESA's exact correction norms, energy-equation scaling, rejection heuristics, or variable-specific floors across a full solve sequence.

## MESA parity checklist

- [x] `x_scale` claims are tied to `solver_support.f90`.
- [x] `correction_weight` claims are tied to `star_data_step_work.inc` and `solver_support.f90`.
- [x] correction-limit claims are tied to `star_solver.f90`.
- [ ] ASTRA still needs benchmark evidence showing whether its simpler scaling policy improves or worsens Newton behavior relative to nearby alternatives.
