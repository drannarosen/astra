# ASTRA Phase 2 `T(\tau)` Atmosphere Design

Date: **March 30, 2026**

This note records the approved next atmosphere slice for ASTRA's classical structure solver. The goal is to move from the current Phase 1 representative-cell Eddington-grey closure to a more explicit one-sided `T(\tau)` photosphere match while preserving ASTRA's current global bootstrap ownership.

## Decision summary

The approved Phase 2 design is:

- keep ASTRA's current outer radius target row,
- keep ASTRA's current outer luminosity target row,
- keep the current packed solve basis `[\ln R, L, \ln T, \ln \rho]`,
- keep luminosity linear in cgs `erg/s`,
- preserve the current solve-owned state contract,
- upgrade only the atmosphere-side thermodynamic reconstruction and the outer-boundary helper semantics.

This is intentionally narrower than a global closure redesign. Phase 2 is an atmosphere hardening slice, not a redefinition of ASTRA's entire stellar model family.

## Why preserve outer `R` and `L` for Phase 2

ASTRA's current surface closure in [src/numerics/boundary_conditions.jl](../../src/numerics/boundary_conditions.jl) still uses explicit rows for

- `R_surface - radius_guess_cm`,
- `L_surface - luminosity_guess_erg_s`,
- and two atmosphere-side thermodynamic rows.

Those first two rows are part of ASTRA's present bootstrap model-family definition. If Phase 2 changed them, the project would no longer be doing "atmosphere physics next." It would be doing a larger global closure redesign in the same slice.

That larger redesign may eventually be the right thing to do. It is not the right next thing to do.

The immediate objective is to harden the outer atmosphere while preserving the current public ownership contract described in [docs/website/methods/staggered-mesh-and-state-layout.md](../website/methods/staggered-mesh-and-state-layout.md).

## Source-backed comparison surfaces

### ASTRA

- [src/numerics/boundary_conditions.jl](../../src/numerics/boundary_conditions.jl)
- [src/numerics/residuals.jl](../../src/numerics/residuals.jl)
- [src/numerics/atmosphere.jl](../../src/numerics/atmosphere.jl)
- [docs/website/physics/atmosphere-and-photosphere.md](../website/physics/atmosphere-and-photosphere.md)
- [docs/website/methods/boundary-condition-realization.md](../website/methods/boundary-condition-realization.md)

### MESA local mirror

- `/Users/anna/projects/jaxstro-dev/legacy/stellax-legacy/reference/mesa/star/dev_cases_test_TDC/dev_TDC_to_cc_12/inlist_common`
- `/Users/anna/projects/jaxstro-dev/legacy/stellax-legacy/reference/mesa/star/private/tdc_hydro_support.f90`

These show an explicit `atm_option = 'T_tau'` path and an atmosphere helper that derives surface `P` and `T` from the current solved outer structure rather than from guessed thermodynamic values.

### Stellax local source history

- `/Users/anna/projects/jaxstro-dev/legacy/stellax-legacy/docs/MESA_IMPLEMENTATION.md`
- `/Users/anna/projects/jaxstro-dev/legacy/stellax-legacy/docs/MESA_DEV/stellax_boundary_conditions_guide.md`

Those notes reinforce the staged atmosphere path:

1. get off guessed thermodynamic surface values,
2. use a robust Eddington-grey baseline,
3. then introduce a more explicit `T(\tau)` boundary before richer atmosphere options.

## Phase 1 status and the remaining gap

Phase 1 already did the high-value first cleanup:

- `T_eff(L, R)` replaced the old hard temperature guess,
- `P_ph ~ (2/3) g / \kappa` replaced the old hard density guess,
- the last transport row became one-sided and atmosphere-aware,
- solver-side row weighting was realigned with the new pressure-row meaning.

That was a real improvement, but it still identifies the outermost thermodynamic cell with the photosphere. The outer cell is acting as if it lived at `\tau = 2/3`.

That is the key approximation Phase 2 should remove.

## Approved Phase 2 physical model

Phase 2 will continue to use an Eddington-grey atmosphere, but it will use the full grey `T(\tau)` relation rather than collapsing everything onto the photosphere:

$$
T^4(\tau) = \frac{3}{4} T_\mathrm{eff}^4 \left(\tau + \frac{2}{3}\right).
$$

The outer face is still interpreted as the photosphere:

$$
\tau_\mathrm{ph} = \frac{2}{3}.
$$

The outermost thermodynamic cell is then matched at a deeper optical depth estimated from a one-sided half-cell column.

### One-sided optical-depth estimate

Define the half-cell surface column mass as

$$
\Sigma_{\frac{1}{2},n} \approx \frac{\Delta m_n}{8 \pi R_\mathrm{surf}^2}.
$$

Then define the half-cell optical-depth increment

$$
\Delta \tau_{\frac{1}{2},n} \approx \kappa_n \Sigma_{\frac{1}{2},n},
$$

with `\kappa_n` supplied by the existing outer-cell opacity helper.

That gives the outer-cell match depth

$$
\tau_{\mathrm{match},n} = \frac{2}{3} + \Delta \tau_{\frac{1}{2},n}.
$$

### Temperature target

The outer-cell temperature target becomes

$$
T_{\mathrm{match},n} =
\left[
\frac{3}{4} T_\mathrm{eff}^4
\left(\tau_{\mathrm{match},n} + \frac{2}{3}\right)
\right]^{1/4}.
$$

This makes the outer cell a one-sided atmosphere reconstruction point rather than the photosphere itself.

### Pressure target

Phase 2 keeps the same grey photospheric pressure scale at the face,

$$
P_\mathrm{ph} \approx \frac{2}{3}\frac{g_\mathrm{surf}}{\kappa_n},
$$

and then reconstructs the cell-center target pressure from the same half-cell column:

$$
P_{\mathrm{match},n} \approx P_\mathrm{ph} + g_\mathrm{surf} \Sigma_{\frac{1}{2},n}.
$$

This is a simple one-sided hydrostatic column estimate. It is not a full atmosphere integration, but it is more faithful than treating the cell center itself as the photosphere.

## Approved discrete interpretation

### Rows that remain unchanged

Keep:

$$
R_{\mathrm{surf},R} = R_\mathrm{surf} - R_\mathrm{target},
$$

$$
R_{\mathrm{surf},L} = L_\mathrm{surf} - L_\mathrm{target}.
$$

These rows continue to define the current bootstrap family.

### Thermodynamic surface rows that change

Replace the Phase 1 representative-cell thermodynamic match with:

$$
R_{\mathrm{surf},T} = \ln T_n - \ln T_{\mathrm{match},n},
$$

$$
R_{\mathrm{surf},P} = P_n - P_{\mathrm{match},n}.
$$

The solve basis remains `(\ln T_n, \ln \rho_n)` through the EOS. Phase 2 does not add a new pressure state variable.

### Outer transport row semantics

The current one-sided outer transport row remains conceptually one-sided to the photospheric face, not to the outer cell center. Phase 2 should keep that ownership, but refactor the helper layer so the photospheric `T` and `P` targets are supplied through the new `T(\tau)` helper family rather than through ad hoc Phase 1 reconstruction.

That means the outer transport row still matches the last interior thermodynamic owner to the photosphere, while the outer boundary rows separately define the reconstructed outer cell thermodynamics.

## Why this is the right next slice

This choice has the best balance of correctness and scope:

- it fixes the specific remaining atmosphere approximation that Phase 1 intentionally left behind,
- it does not widen the public ownership contract,
- it keeps the model-family question separate from the atmosphere question,
- it uses the same source-backed staged path that MESA/Stellax experience suggests is robust,
- and it sets up a later global-closure redesign without forcing it into the same slice.

## What Phase 2 does not do

Phase 2 does **not**:

- remove the current outer `R` target row,
- remove the current outer `L` target row,
- add a new solve-owned atmosphere state block,
- add atmosphere tables,
- add non-Eddington `T(\tau)` relations,
- redesign solver globalization.

Those remain later tasks.

## Follow-on roadmap after Phase 2

### Later atmosphere work

- support alternative `T(\tau)` relations such as Krishna Swamy,
- evaluate whether ASTRA should own a more explicit diagnostic photosphere state,
- benchmark the convergence-basin effect of the new atmosphere semantics.

### Later global-closure work

- revisit whether luminosity should become emergent before radius does,
- revisit whether both outer `R` and `L` should remain target rows in the long run,
- design a dedicated global closure project rather than mixing it into atmosphere hardening.

## Design checklist

- [x] Preserve the current outer `R` target row in Phase 2.
- [x] Preserve the current outer `L` target row in Phase 2.
- [x] Keep the current packed solve basis `[\ln R, L, \ln T, \ln \rho]`.
- [x] Move the photosphere to the outer face rather than the outer cell center.
- [x] Define a one-sided half-cell optical-depth estimate for the outer-cell match point.
- [x] Use Eddington `T(\tau)` for the outer-cell temperature target.
- [x] Use a one-sided hydrostatic column estimate for the outer-cell pressure target.
- [x] Keep the outer transport semantics one-sided to the photospheric face.
- [x] Keep richer atmosphere options and global-closure redesign out of scope for this slice.
