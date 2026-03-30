# ASTRA Atmosphere Boundary Design

Date: **March 30, 2026**

This note records the approved design direction for ASTRA's next classical-structure hardening slice: replace the provisional outer thermodynamic closure with an Eddington-grey atmosphere match while preserving ASTRA's current solve-owned state contract.

## Motivation

ASTRA's current classical lane closes the outer boundary with explicit target rows for:

- outer radius,
- outer luminosity,
- surface temperature guess,
- surface density guess.

The current implementation lives in [src/numerics/boundary_conditions.jl](../../src/numerics/boundary_conditions.jl), while the interior transport row still uses the generic interior stencil in [src/numerics/residuals.jl](../../src/numerics/residuals.jl).

That combination is now the clearest remaining structural weakness in the classical solve:

- the weighted residual audit shows the dominant solver failure is the surface-density row,
- the next-largest weighted failure is the outermost transport row,
- the existing surface closure is documented as provisional in [docs/website/physics/boundary-conditions.md](../website/physics/boundary-conditions.md),
- and local MESA evidence shows that production behavior derives `P_surf` and `T_surf` from atmosphere machinery rather than pinning hard thermodynamic guesses.

This slice therefore targets boundary meaning, not just Newton control.

## Source-backed comparison surfaces

### ASTRA

- [src/numerics/boundary_conditions.jl](../../src/numerics/boundary_conditions.jl)
- [src/numerics/residuals.jl](../../src/numerics/residuals.jl)
- [src/numerics/structure_equations.jl](../../src/numerics/structure_equations.jl)
- [docs/website/physics/boundary-conditions.md](../website/physics/boundary-conditions.md)
- [docs/website/methods/boundary-condition-realization.md](../website/methods/boundary-condition-realization.md)
- [docs/website/methods/staggered-mesh-and-state-layout.md](../website/methods/staggered-mesh-and-state-layout.md)

### MESA local mirror

- `/Users/anna/projects/jaxstro-dev/legacy/stellax-legacy/reference/mesa/star/private/tdc_hydro_support.f90`
- `/Users/anna/projects/jaxstro-dev/legacy/stellax-legacy/reference/mesa/star/dev_cases_test_TDC/dev_TDC_to_cc_12/inlist_common`

The key evidence is that `get_PT_surf2` calls `get_atm_PT(...)` using the current solved outer structure (`L`, `r`, `m`, `g`, opacity) and returns `P_surf` and `T_surf`. The inlist evidence also shows an explicit `T_tau` atmosphere path with `atm_T_tau_relation = 'Eddington'`.

### Stellax local source history

- `/Users/anna/projects/jaxstro-dev/legacy/stellax-legacy/docs/MESA_numerical_methods.md`
- `/Users/anna/projects/jaxstro-dev/legacy/stellax-legacy/docs/MESA_DEV/stellax_boundary_conditions_guide.md`
- `/Users/anna/projects/jaxstro-dev/legacy/stellax-legacy/archive/dev-notes/HENYEY_SUMMARY.md`

Those notes consistently converge on the same staged strategy:

1. start with Eddington-grey,
2. then move to a better `tau = 2/3` or `T(tau)` atmosphere treatment,
3. then later support richer atmosphere models.

That sequence is the right comparison surface for ASTRA: it is source-backed, it reflects actual prior debugging pain, and it matches ASTRA's current need for a robust minimal slice.

## Current ASTRA ownership constraints

The current solve-owned structure state is:

- face-centered `log_radius_face_cm`,
- face-centered `luminosity_face_erg_s`,
- cell-centered `log_temperature_cell_k`,
- cell-centered `log_density_cell_g_cm3`.

That contract is canonical in [docs/website/methods/staggered-mesh-and-state-layout.md](../website/methods/staggered-mesh-and-state-layout.md).

The immediate atmosphere slice must preserve:

- `StellarModel` with explicit `StructureState`, `CompositionState`, `EvolutionState`,
- packed basis `[\ln R, L, \ln T, \ln \rho]`,
- linear cgs luminosity,
- the current solve-owned block shape,
- explicit local derivative helpers,
- and Jacobian validation discipline.

## The design question

The key design choice is whether ASTRA should also change the meaning of the outer `R` and `L` rows now.

### Rejected approach: change outer `R` and `L` ownership in this slice

Changing the outer `R` and `L` rows right now would mean changing ASTRA's current global model-family contract. Today the bootstrap lane is effectively solving a specified `(M, R, L)` family member. Removing or replacing those rows would begin an eigenvalue or relaxation redesign rather than a local boundary hardening pass.

That may be the right long-term direction, but it is larger than the approved slice.

### Approved approach: preserve outer `R` and `L`, replace only outer thermodynamics and outer transport

The approved design is:

- keep the current outer radius target row,
- keep the current outer luminosity target row,
- replace the hard surface-temperature guess row,
- replace the hard surface-density guess row,
- replace the outermost transport treatment so the last thermodynamic owner is matched to the atmosphere semantics rather than forced through a generic interior stencil.

This preserves ASTRA's current global ownership while fixing the boundary rows that are actually failing.

## Approved Eddington-grey boundary realization

### Physical ingredients

Define the surface effective temperature from the current outer face radius and luminosity:

$$
T_\mathrm{eff} = \left(\frac{L_\mathrm{surf}}{4 \pi \sigma R_\mathrm{surf}^2}\right)^{1/4}.
$$

Define surface gravity from the current outer mass and radius:

$$
g_\mathrm{surf} = \frac{G M_\mathrm{surf}}{R_\mathrm{surf}^2}.
$$

Define the Eddington-grey photospheric pressure target using the outer-cell opacity:

$$
P_\mathrm{ph} = \frac{2}{3}\frac{g_\mathrm{surf}}{\kappa_\mathrm{outer}}.
$$

This is the minimal grey-atmosphere closure ASTRA can support without changing the public state contract.

### Discrete interpretation

For this slice only, the outermost thermodynamic cell is treated as the photospheric representative cell.

That is an approximation, not a final atmosphere discretization.

It means:

- the outer cell temperature represents `T_ph`,
- the outer cell density is constrained through the EOS to represent `rho_ph`,
- the outer cell opacity supplies the `kappa` used in the Eddington pressure estimate,
- and the outer transport row must be made consistent with this one-sided surface interpretation.

### Residual rows to keep

Keep:

$$
R_{\mathrm{surf},R} = R_\mathrm{surf} - R_\mathrm{target},
$$

$$
R_{\mathrm{surf},L} = L_\mathrm{surf} - L_\mathrm{target}.
$$

These continue to define the current bootstrap model family.

### Residual rows to replace

Replace the current hard temperature guess row with:

$$
R_{\mathrm{surf},T} = \ln T_\mathrm{outer} - \ln T_\mathrm{eff}.
$$

Replace the current hard density guess row with an EOS-pressure match:

$$
R_{\mathrm{surf},P} = P_\mathrm{EOS}(\rho_\mathrm{outer}, T_\mathrm{outer}) - P_\mathrm{ph}.
$$

This keeps ASTRA in its current `(\rho, T)` thermodynamic basis instead of inventing a new surface-pressure state variable.

## Approved outer transport redesign

The current generic transport row is:

$$
R_{T,k} = \ln T_{k+1} - \ln T_k + \nabla_k \left(\ln P_{k+1} - \ln P_k\right).
$$

That interior form is appropriate for interior cell-to-cell matching, but it is not the correct owner at the outer edge once the surface is defined by atmosphere matching.

### Approved boundary-side replacement

Replace the final transport row with a one-sided outer transport match that ties the outermost interior thermodynamic state to the photospheric target:

$$
R_{T,\mathrm{outer}} =
\ln T_\mathrm{ph} - \ln T_{n-1}
+ \nabla_{n-1}\left(\ln P_\mathrm{ph} - \ln P_{n-1}\right).
$$

For the Eddington-grey slice:

- `T_ph = T_eff`,
- `P_ph = (2/3) g_\mathrm{surf} / \kappa_\mathrm{outer}`,
- `\nabla_{n-1}` remains ASTRA's current radiative-gradient helper.

This is still approximate, but it is boundary-consistent in a way the current interior-style last stencil is not.

## What this slice does not do

This design explicitly does **not**:

- add a new solve-owned photospheric state,
- integrate optical depth through multiple outer layers,
- add atmosphere tables,
- change ASTRA's current outer `R` or `L` ownership,
- change ASTRA into a full MESA-style atmosphere module,
- widen scope into convection-aware atmosphere coupling.

Those are downstream phases.

## Planned atmosphere phases

### Phase 0: current bootstrap closure

- keep outer `R` and `L` target rows,
- hard surface `T` guess,
- hard surface `rho` guess,
- generic interior-style last transport row.

Status: current baseline, known to be structurally provisional.

### Phase 1: Eddington-grey representative-cell closure

- keep outer `R` and `L` target rows,
- set `T_outer = T_eff(L, R)`,
- set `P_outer = (2/3) g / kappa`,
- enforce EOS consistency through `P_EOS(rho_outer, T_outer)`,
- replace the last transport row with a one-sided boundary match.

Status: approved next slice.

### Phase 2: explicit `T(tau)` one-sided atmosphere match

- introduce a diagnostic photospheric match that does not identify the outer cell center with the photosphere exactly,
- evaluate a one-sided `T(tau)` relation from the last interior cell to `tau = 2/3`,
- use a more consistent outer pressure/temperature reconstruction,
- retain ASTRA's public ownership contract if feasible.

Status: planned after Phase 1 works.

### Phase 3: richer atmosphere options

- support alternative `T(tau)` relations,
- potentially support tabulated atmosphere surfaces,
- decide whether ASTRA should add explicit atmosphere-owned boundary data or keep the current compressed closure.

Status: explicitly deferred.

## Documentation changes required

### New physics page

Add a new canonical physics page:

- `docs/website/physics/atmosphere-and-photosphere.md`

It should explain:

- what a stellar photosphere is,
- why `tau = 2/3` is the standard Eddington marker,
- how `T_eff`, `P_ph`, `g`, and `kappa` connect,
- what ASTRA currently implements,
- what remains staged or deferred,
- and the planned phases above with an explicit checklist.

### Existing docs to update

- `docs/website/physics/boundary-conditions.md`
- `docs/website/methods/boundary-condition-realization.md`
- `docs/website/methods/residual-assembly.md`
- `docs/website/methods/overview.md`
- `docs/website/development/progress-summary.md`
- `docs/website/development/changelog.md`
- relevant development checklist page(s)

The docs must be honest that Phase 1 is a representative-cell approximation, not final atmosphere physics.

## Testing consequences

The atmosphere slice needs targeted tests for:

- correct `T_eff(L, R)` evaluation,
- correct `P_ph(g, kappa)` evaluation,
- packed basis preservation with linear `L`,
- EOS-based outer pressure row meaning,
- one-sided outer transport row meaning,
- Jacobian fidelity for the new boundary rows,
- no regression in center rows or interior geometry / hydrostatic / luminosity rows,
- improved weighted outer-boundary residual behavior on the default toy problem.

## Detailed checklist

### Scientific ownership checklist

- [x] Preserve the packed solve basis `[\ln R, L, \ln T, \ln \rho]`.
- [x] Preserve linear cgs luminosity.
- [x] Preserve ASTRA's current top-level `StellarModel` ownership contract.
- [x] Preserve outer `R` and `L` target rows for this slice.
- [x] Replace provisional thermodynamic surface guesses with atmosphere-derived targets.
- [x] Replace the final transport row with a boundary-consistent one-sided match.
- [ ] Revisit outer `R` and `L` ownership in a later dedicated design note.

### Numerics checklist

- [ ] Add local helper(s) for `T_eff`, `g_surface`, and `P_ph`.
- [ ] Add analytic or locally differentiated derivatives for the new boundary rows.
- [ ] Extend solver metrics and diagnostics to report outer-boundary row-family behavior honestly.
- [ ] Preserve Jacobian audit discipline for the new rows.

### Validation checklist

- [ ] Add failing tests for the new atmosphere helpers and row assembly before code changes.
- [ ] Add failing tests for the new outer transport row semantics before code changes.
- [ ] Show that the dominant weighted outer residual is no longer the old hard surface-density row.
- [ ] Re-run the required Newton, Jacobian, docs, and package validation commands after implementation.

### Documentation checklist

- [ ] Add the new atmosphere physics page.
- [ ] Add a phases section and atmosphere checklist to the website.
- [ ] Cross-link atmosphere, boundary, and residual pages.
- [ ] State explicitly what is current, what is staged, and what is deferred.

## Recommendation

Implement Phase 1 exactly as specified above.

This is the best immediate design because it:

- targets the actual failing boundary semantics,
- preserves ASTRA's current ownership contract,
- uses the same staged strategy that MESA and Stellax source evidence justify,
- and creates a scientifically honest bridge to a later `T(tau)` atmosphere design.
