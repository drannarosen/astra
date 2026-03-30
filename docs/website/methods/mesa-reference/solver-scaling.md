# Solver Scaling in MESA

The comparison here is source-backed, not aspirational. The local MESA files `star/private/solver_support.f90` and `star/private/star_utils.f90` show that solve-time scaling is handled explicitly through `x_scale`, `correction_weight`, and a separate energy-equation scaling helper.

## file-backed parity

In `set_xscale_info`, MESA assigns per-variable scaling factors through `s% x_scale(i,k)`. The logic distinguishes structure variables from abundance variables, and it uses the current solve state to keep corrections numerically sized for the Newton solve.

In `sizeB`, MESA assigns `s% correction_weight(j,k)` and uses those weights when it reports correction norms and correction limits. That is the direct source-backed pattern ASTRA is comparing against.

In `set_energy_eqn_scal(...)`, MESA also carries an explicit residual-scale hook for the energy equation. That matters because it shows MESA is conditioning both corrections and at least one residual family directly in solver-support code.

## partial parity

ASTRA shares the same high-level goal: keep luminosity in physical `erg/s` and scale the solve numerically rather than redefining the physics variable. That is partial parity, because ASTRA's scaling is much simpler and does not reproduce MESA's full per-variable machinery.

## analogy only

Any claim that ASTRA has MESA's complete correction-limit behavior would be analogy only at this stage. The local source clearly shows additional MESA logic around retry handling and variable-specific safeguards that ASTRA does not yet mirror.

## not yet proven

We have not yet shown that ASTRA's scaling choices reproduce MESA's exact correction norms, energy-equation scaling, rejection heuristics, or variable-specific floors across a full solve sequence.
