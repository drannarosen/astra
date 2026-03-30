# Phase 2 `T(\tau)` Atmosphere Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace ASTRA's Phase 1 representative-cell Eddington-grey atmosphere closure with a one-sided Phase 2 `T(\tau)` photosphere match while preserving ASTRA's current outer `R/L` ownership and packed structure state.

**Architecture:** This plan keeps the current solve-owned state and the current outer `R_surface` and `L_surface` target rows. The implementation adds local `T(\tau)` and half-cell column helpers, rewrites only the outer thermodynamic boundary targets and the associated helper semantics, preserves the one-sided photospheric transport ownership, and extends tests and docs so the new atmosphere meaning is explicit and falsifiable. The user explicitly requested work on `main` without a worktree, so execute in the current checkout.

**Tech Stack:** Julia 1.12, stdlib `Test`, current ASTRA numerics and docs stack, MystMD docs, @test-driven-development, @scientific-collaborator-mode, @verification-before-completion

---

### Task 1: Add `T(\tau)` Atmosphere Helper Tests

**Files:**
- Create: `test/test_atmosphere_ttau_helpers.jl`
- Modify: `test/runtests.jl`
- Modify: `src/numerics/atmosphere.jl`
- Modify: `src/ASTRA.jl`

**Step 1: Write the failing test**

Create `test/test_atmosphere_ttau_helpers.jl`:

```julia
using Test
using ASTRA

@testset "T(tau) helpers" begin
    teff_k = ASTRA.SOLAR_EFFECTIVE_TEMPERATURE_K
    tau_ph = 2.0 / 3.0
    tau_deeper = tau_ph + 0.25

    t_ph = ASTRA.eddington_t_tau_temperature_k(teff_k, tau_ph)
    t_deeper = ASTRA.eddington_t_tau_temperature_k(teff_k, tau_deeper)

    @test t_ph ≈ teff_k rtol = 1e-12
    @test t_deeper > t_ph

    dm_half_g = 1.0e29
    radius_cm = ASTRA.SOLAR_RADIUS_CM
    opacity_cm2_g = 0.34
    sigma_half = ASTRA.outer_half_cell_column_density_g_cm2(dm_half_g, radius_cm)
    delta_tau = ASTRA.outer_half_cell_optical_depth(opacity_cm2_g, sigma_half)

    @test sigma_half > 0.0
    @test delta_tau > 0.0
end
```

**Step 2: Run test to verify it fails**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_atmosphere_ttau_helpers.jl")'
```

Expected: FAIL because the `T(\tau)` helpers do not exist yet.

**Step 3: Write minimal implementation**

In `src/numerics/atmosphere.jl`, add:

- `eddington_t_tau_temperature_k(teff_k, tau)`
- `outer_half_cell_column_density_g_cm2(dm_cell_g, radius_surface_cm)`
- `outer_half_cell_optical_depth(opacity_cm2_g, sigma_half_g_cm2)`
- helper guards for positive `tau`, `radius`, and opacity inputs using existing positive-clamp conventions

Update `src/ASTRA.jl` so the helpers are available to tests.

**Step 4: Run test to verify it passes**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_atmosphere_ttau_helpers.jl")'
```

Expected: PASS with `T(2/3) = T_eff` and positive half-cell column/optical-depth values.

**Step 5: Commit**

```bash
git add test/test_atmosphere_ttau_helpers.jl test/runtests.jl src/numerics/atmosphere.jl src/ASTRA.jl
git commit -m "feat: add phase 2 t-tau atmosphere helpers"
```

### Task 2: Add One-Sided Match-Point Reconstruction Tests

**Files:**
- Create: `test/test_atmosphere_match_point.jl`
- Modify: `test/runtests.jl`
- Modify: `src/numerics/atmosphere.jl`

**Step 1: Write the failing test**

Create `test/test_atmosphere_match_point.jl`:

```julia
using Test
using ASTRA

@testset "outer atmosphere match point" begin
    problem = ASTRA.build_toy_problem(n_cells = 12)
    model = ASTRA.initialize_state(problem)
    n = problem.grid.n_cells

    radius_surface_cm = exp(model.structure.log_radius_face_cm[end])
    luminosity_surface_erg_s = model.structure.luminosity_face_erg_s[end]
    teff_k = ASTRA.surface_effective_temperature_k(radius_surface_cm, luminosity_surface_erg_s)
    opacity_outer = ASTRA.cell_opacity_state(problem, model, n).opacity_cm2_g
    g_surface = ASTRA.surface_gravity_cgs(problem.parameters.mass_g, radius_surface_cm)

    tau_match = ASTRA.outer_match_optical_depth(problem, model)
    t_match = ASTRA.outer_match_temperature_k(problem, model)
    p_match = ASTRA.outer_match_pressure_dyn_cm2(problem, model)
    p_ph = ASTRA.eddington_photospheric_pressure_dyn_cm2(g_surface, opacity_outer)

    @test tau_match > 2.0 / 3.0
    @test t_match > teff_k
    @test p_match > p_ph
end
```

**Step 2: Run test to verify it fails**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_atmosphere_match_point.jl")'
```

Expected: FAIL because the one-sided match-point helpers do not exist yet.

**Step 3: Write minimal implementation**

In `src/numerics/atmosphere.jl`, add:

- `outer_match_optical_depth(problem, model)`
- `outer_match_temperature_k(problem, model)`
- `outer_match_pressure_dyn_cm2(problem, model)`

Implementation requirements:

- use the outer-face photosphere at `tau = 2/3`,
- use the outer-cell opacity and half-cell column estimate,
- compute the match temperature through the Eddington `T(\tau)` relation,
- compute the match pressure through `P_ph + g * Sigma_half`,
- do not create a new solve-owned surface state type.

**Step 4: Run test to verify it passes**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_atmosphere_match_point.jl")'
```

Expected: PASS with a deeper-than-photosphere match point.

**Step 5: Commit**

```bash
git add test/test_atmosphere_match_point.jl test/runtests.jl src/numerics/atmosphere.jl
git commit -m "feat: add one-sided atmosphere match-point helpers"
```

### Task 3: Replace Surface Thermodynamic Rows With Phase 2 Match Targets

**Files:**
- Modify: `test/test_boundary_conditions.jl`
- Modify: `src/numerics/boundary_conditions.jl`

**Step 1: Write the failing test**

Extend `test/test_boundary_conditions.jl`:

```julia
@testset "surface boundary uses phase 2 t-tau targets" begin
    problem = ASTRA.build_toy_problem(n_cells = 12)
    model = ASTRA.initialize_state(problem)
    n = problem.grid.n_cells

    residual = ASTRA.surface_boundary_residual(problem, model)
    radius_surface_cm = exp(model.structure.log_radius_face_cm[end])
    luminosity_surface_erg_s = model.structure.luminosity_face_erg_s[end]
    pressure_outer = ASTRA.cell_eos_state(problem, model, n).pressure_dyn_cm2

    @test residual[1] ≈ radius_surface_cm - problem.parameters.radius_guess_cm
    @test residual[2] ≈ luminosity_surface_erg_s - problem.parameters.luminosity_guess_erg_s
    @test residual[3] ≈ model.structure.log_temperature_cell_k[n] - log(ASTRA.outer_match_temperature_k(problem, model))
    @test residual[4] ≈ pressure_outer - ASTRA.outer_match_pressure_dyn_cm2(problem, model)
end
```

**Step 2: Run test to verify it fails**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_boundary_conditions.jl")'
```

Expected: FAIL because the current Phase 1 residual still targets the representative-cell photosphere values.

**Step 3: Write minimal implementation**

In `src/numerics/boundary_conditions.jl`:

- keep rows 1 and 2 unchanged,
- replace the temperature row target with `outer_match_temperature_k(problem, model)`,
- replace the pressure row target with `outer_match_pressure_dyn_cm2(problem, model)`,
- keep the residual meaning explicit in code comments only where the one-sided match is not obvious.

**Step 4: Run test to verify it passes**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_boundary_conditions.jl")'
```

Expected: PASS with the new Phase 2 thermodynamic boundary targets.

**Step 5: Commit**

```bash
git add test/test_boundary_conditions.jl src/numerics/boundary_conditions.jl
git commit -m "feat: use phase 2 t-tau surface targets"
```

### Task 4: Reconcile Outer Transport, Jacobian Audit, And Solver Metrics

**Files:**
- Modify: `test/test_outer_transport_boundary.jl`
- Modify: `test/test_jacobian_fidelity_audit.jl`
- Modify: `test/test_weighted_solver_metrics.jl`
- Modify: `src/numerics/residuals.jl`
- Modify: `src/numerics/jacobians.jl`
- Modify: `src/solvers/step_metrics.jl`

**Step 1: Write the failing test**

Update `test/test_outer_transport_boundary.jl` so it asserts the outer transport row is still one-sided to the photospheric face, but now uses the shared Phase 2 atmosphere helpers for the face targets.

Add a Jacobian-fidelity assertion in `test/test_jacobian_fidelity_audit.jl` that the modified outer boundary still satisfies the packed-basis finite-difference audit.

Add a weighted-metric assertion in `test/test_weighted_solver_metrics.jl` that the surface pressure row remains pressure-scaled and finite under the new Phase 2 target helpers.

**Step 2: Run tests to verify they fail**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_outer_transport_boundary.jl"); include("test/test_jacobian_fidelity_audit.jl"); include("test/test_weighted_solver_metrics.jl")'
```

Expected: FAIL because the row builders and metric helpers still assume the Phase 1 reconstruction path.

**Step 3: Write minimal implementation**

In `src/numerics/residuals.jl`:

- keep the one-sided outer transport ownership,
- route the photospheric face targets through the new Phase 2 atmosphere helper layer,
- avoid changing unrelated interior rows.

In `src/numerics/jacobians.jl`:

- keep the packed-basis chain rule unchanged,
- update the outer-row helper use so the audit compares against the new residual meaning.

In `src/solvers/step_metrics.jl`:

- keep the current corrected temperature/pressure row semantics,
- update any helper naming or row-family assumptions that still refer to the Phase 1 representative-cell interpretation.

**Step 4: Run tests to verify they pass**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_outer_transport_boundary.jl"); include("test/test_jacobian_fidelity_audit.jl"); include("test/test_weighted_solver_metrics.jl")'
```

Expected: PASS with preserved Jacobian fidelity and semantically correct weighted surface metrics.

**Step 5: Commit**

```bash
git add test/test_outer_transport_boundary.jl test/test_jacobian_fidelity_audit.jl test/test_weighted_solver_metrics.jl src/numerics/residuals.jl src/numerics/jacobians.jl src/solvers/step_metrics.jl
git commit -m "feat: align outer transport with phase 2 atmosphere helpers"
```

### Task 5: Record The New Atmosphere Contract In Docs And Validate

**Files:**
- Modify: `docs/website/physics/atmosphere-and-photosphere.md`
- Modify: `docs/website/physics/boundary-conditions.md`
- Modify: `docs/website/methods/boundary-condition-realization.md`
- Modify: `docs/website/development/progress-summary.md`
- Modify: `docs/website/development/checklists/solar-first-lane.md`
- Modify: `test/test_docs_structure.jl`

**Step 1: Write the failing test**

Extend `test/test_docs_structure.jl` so it asserts the atmosphere docs mention:

- Phase 2 `T(\tau)` explicitly,
- the decision to preserve outer `R` and `L` in that slice,
- and the fact that a wider global-closure redesign is deferred.

**Step 2: Run test to verify it fails**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_docs_structure.jl")'
```

Expected: FAIL until the website docs describe the approved Phase 2 design.

**Step 3: Write minimal implementation**

Update the website docs so they:

- explain the Phase 1 to Phase 2 transition clearly,
- state that Phase 2 preserves current outer `R/L` ownership,
- describe the one-sided `T(\tau)` match as the next implementation target,
- keep the current-vs-planned-vs-deferred status explicit.

**Step 4: Run test to verify it passes**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_docs_structure.jl")'
cd /Users/anna/projects/julia-dev/astra/docs/website && myst build --site --html --strict
```

Expected: PASS with strict docs build success.

**Step 5: Commit**

```bash
git add docs/website/physics/atmosphere-and-photosphere.md docs/website/physics/boundary-conditions.md docs/website/methods/boundary-condition-realization.md docs/website/development/progress-summary.md docs/website/development/checklists/solar-first-lane.md test/test_docs_structure.jl
git commit -m "docs: record phase 2 t-tau atmosphere contract"
```

### Task 6: Run The Full Required Verification Suite

**Files:**
- No code changes expected

**Step 1: Run the required targeted verification**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_center_asymptotic_scaling.jl")'
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_jacobian_fidelity_audit.jl")'
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_default_newton_progress.jl"); include("test/test_convergence_basin.jl")'
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_docs_structure.jl")'
cd /Users/anna/projects/julia-dev/astra/docs/website && myst build --site --html --strict
~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
```

Expected:

- targeted atmosphere, boundary, metric, and Jacobian tests PASS,
- docs structure and strict Myst build PASS,
- full package test suite PASS.

**Step 2: Record the verification evidence**

Summarize:

- which commands ran,
- whether the default classical solve improved or regressed,
- what still remains deferred after Phase 2 lands.

**Step 3: Commit any final docs/test adjustments**

If verification required a small wording-only doc update or a narrowly scoped test expectation refresh, commit it separately:

```bash
git add <exact files>
git commit -m "test: refresh phase 2 atmosphere verification expectations"
```

If no verification-driven changes were needed, do not create an empty commit.
