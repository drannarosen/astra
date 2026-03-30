# Solver Scaling in MESA

The comparison here is source-backed, not aspirational. The key local MESA files are:

- `star_data/public/star_data_step_work.inc`
- `star/private/solver_support.f90`
- `star/private/star_solver.f90`
- `star/private/hydro_momentum.f90`
- `star/private/hydro_eqns.f90`

## file-backed parity

`star_data_step_work.inc` declares solver work arrays `x_scale`, `residual_weight`, and `correction_weight`. That is the first file-backed sign that MESA treats conditioning as explicit solver state rather than as an invisible implementation detail.

In `set_xscale_info` inside `solver_support.f90`, MESA assigns per-variable scaling factors through `s% x_scale(i,k)`. The logic distinguishes structure variables from abundance variables and, for ordinary structure variables, scales by the magnitude of the current starting state `abs(s% xh_start(i,k))` with a floor.

In `eval_equations` inside `solver_support.f90`, MESA resets `s% residual_weight(j,k)` and `s% correction_weight(j,k)` before evaluating equations, then later in the same file assigns variable-specific `correction_weight` entries such as the luminosity weight `1d0/(frac*s% L_start(1) + abs(s% L(k)))`.

In `star_solver.f90`, MESA computes `correction_norm` and `max_abs_correction` using those scaled corrections and then limits the applied correction using `scale_correction_norm` and `scale_max_correction`.

The MESA audit also shows that important row scaling happens inside the equations themselves. In `hydro_momentum.f90`, the momentum residual is normalized by `1/(avg Ptot)`. In `hydro_eqns.f90`, several surface and transport-adjacent rows divide by explicit local scales rather than leaving the equation in raw units. In the files inspected here, `residual_weight` remains at `1d0`, so the stronger pattern is not "MESA solved this with one universal residual-weight table." The stronger pattern is layered conditioning: variable scaling, equation-local normalization, and correction-domain guards together.

That combination is the file-backed pattern ASTRA should use as its reference surface: explicit variable scaling where needed, equation-local or metric-local normalization where the row family is locally sharp, and explicit correction-size limits.

## partial parity

ASTRA shares the same high-level goal: keep luminosity in physical `erg/s` and scale the solve numerically rather than redefining the physics variable. That is partial parity, because ASTRA's scaling is much simpler and does not reproduce MESA's full per-variable machinery.

The current best ASTRA analogue is not a literal clone of `x_scale` across every packed variable. ASTRA already gains part of that scaling from the log basis itself for `R`, `T`, and `\rho`. The closer partial-parity move is therefore to harden transport-local normalization and boundary-domain guards before broadening global scaling policy.

## analogy only

Any claim that ASTRA has MESA's complete correction-limit behavior would be analogy only at this stage. The local source clearly shows additional MESA logic around retry handling and variable-specific safeguards that ASTRA does not yet mirror.

## not yet proven

We have not yet shown that ASTRA's scaling choices reproduce MESA's exact correction norms, equation-local scaling, rejection heuristics, or variable-specific floors across a full solve sequence.

## MESA parity checklist

- [x] `x_scale` claims are tied to `solver_support.f90`.
- [x] `correction_weight` claims are tied to `star_data_step_work.inc` and `solver_support.f90`.
- [x] correction-limit claims are tied to `star_solver.f90`.
- [ ] ASTRA still needs benchmark evidence showing whether its simpler scaling policy improves or worsens Newton behavior relative to nearby alternatives.
