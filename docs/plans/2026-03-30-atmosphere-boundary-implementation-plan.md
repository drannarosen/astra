# Atmosphere Boundary Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace ASTRA's provisional outer thermodynamic closure with an Eddington-grey atmosphere match, replace the outermost transport semantics with a boundary-consistent one-sided row, and add a canonical atmosphere page plus phased documentation and checklists.

**Architecture:** This plan preserves ASTRA's public structure state and current `(M, R, L)` bootstrap family definition. The implementation adds local atmosphere helper functions, rewrites only the outer thermodynamic boundary rows plus the final transport row, extends Jacobian and diagnostics coverage for the new boundary semantics, and documents the phased atmosphere roadmap honestly. The user explicitly requested work on `main` without a worktree, so execute this plan in the current checkout rather than creating one.

**Tech Stack:** Julia 1.12, stdlib `Test`, current ASTRA package scaffold, analytical EOS/opacity bundle, MystMD docs, @test-driven-development, @scientific-collaborator-mode, @verification-before-completion

---

### Task 1: Add Eddington-Grey Atmosphere Helper Coverage

**Files:**
- Create: `test/test_atmosphere_boundary_helpers.jl`
- Modify: `test/runtests.jl`
- Create: `src/numerics/atmosphere.jl`
- Modify: `src/ASTRA.jl`

**Step 1: Write the failing test**

Create `test/test_atmosphere_boundary_helpers.jl`:

```julia
using Test
using ASTRA

@testset "atmosphere boundary helpers" begin
    radius_cm = ASTRA.SOLAR_RADIUS_CM
    luminosity_erg_s = ASTRA.SOLAR_LUMINOSITY_ERG_S
    mass_g = ASTRA.SOLAR_MASS_G
    opacity_cm2_g = 0.34

    teff_k = ASTRA.surface_effective_temperature_k(radius_cm, luminosity_erg_s)
    g_surface = ASTRA.surface_gravity_cgs(mass_g, radius_cm)
    p_ph = ASTRA.eddington_photospheric_pressure_dyn_cm2(g_surface, opacity_cm2_g)

    @test teff_k ≈ ASTRA.SOLAR_EFFECTIVE_TEMPERATURE_K rtol = 5e-3
    @test g_surface > 0.0
    @test p_ph ≈ (2.0 / 3.0) * g_surface / opacity_cm2_g rtol = 1e-12
end
```

This test should prove the atmosphere helpers are explicit, local, and scientifically legible before any boundary rows are changed.

**Step 2: Run test to verify it fails**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_atmosphere_boundary_helpers.jl")'
```

Expected: FAIL because the atmosphere helper surface does not exist yet.

**Step 3: Write minimal implementation**

Create `src/numerics/atmosphere.jl` with:

- `surface_effective_temperature_k(radius_cm, luminosity_erg_s)`
- `surface_gravity_cgs(mass_g, radius_cm)`
- `eddington_photospheric_pressure_dyn_cm2(g_surface_cgs, opacity_cm2_g)`

Requirements:

- keep all helpers local and explicit,
- use cgs units throughout,
- clamp only through existing positive-guard helpers where necessary,
- do not add a new dependency or a new public state block.

Update `src/ASTRA.jl` so these helpers are included and exported if needed by tests.

**Step 4: Run test to verify it passes**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_atmosphere_boundary_helpers.jl")'
```

Expected: PASS with a near-solar `T_eff` and exact Eddington pressure relation.

**Step 5: Commit**

```bash
git add test/test_atmosphere_boundary_helpers.jl test/runtests.jl src/numerics/atmosphere.jl src/ASTRA.jl
git commit -m "feat: add atmosphere boundary helpers"
```

### Task 2: Replace Surface Temperature And Density Guess Rows

**Files:**
- Modify: `test/test_boundary_conditions.jl`
- Modify: `src/numerics/boundary_conditions.jl`
- Modify: `src/numerics/structure_equations.jl`

**Step 1: Write the failing test**

Extend `test/test_boundary_conditions.jl` with a focused atmosphere-boundary test:

```julia
@testset "surface boundary uses atmosphere targets" begin
    problem = ASTRA.build_toy_problem(n_cells = 12)
    model = ASTRA.initialize_state(problem)

    residual = ASTRA.surface_boundary_residual(problem, model)

    radius_surface_cm = exp(model.structure.log_radius_face_cm[end])
    luminosity_surface_erg_s = model.structure.luminosity_face_erg_s[end]
    temperature_outer_k = exp(model.structure.log_temperature_cell_k[end])
    density_outer_g_cm3 = exp(model.structure.log_density_cell_g_cm3[end])

    teff_k = ASTRA.surface_effective_temperature_k(radius_surface_cm, luminosity_surface_erg_s)
    opacity_outer = ASTRA.cell_opacity_state(problem, model, problem.grid.n_cells).opacity_cm2_g
    g_surface = ASTRA.surface_gravity_cgs(problem.parameters.mass_g, radius_surface_cm)
    p_ph = ASTRA.eddington_photospheric_pressure_dyn_cm2(g_surface, opacity_outer)
    p_outer = ASTRA.cell_eos_state(problem, model, problem.grid.n_cells).pressure_dyn_cm2

    @test residual[1] ≈ radius_surface_cm - problem.parameters.radius_guess_cm
    @test residual[2] ≈ luminosity_surface_erg_s - problem.parameters.luminosity_guess_erg_s
    @test residual[3] ≈ log(temperature_outer_k) - log(teff_k)
    @test residual[4] ≈ p_outer - p_ph
    @test residual[4] != density_outer_g_cm3 - 1.0e-7
end
```

This test should force the outer thermodynamic rows to become atmosphere-derived rather than guess-derived.

**Step 2: Run test to verify it fails**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_boundary_conditions.jl")'
```

Expected: FAIL because the current rows still enforce a temperature guess and fixed density guess.

**Step 3: Write minimal implementation**

In `src/numerics/boundary_conditions.jl`:

- keep the current radius and luminosity target rows unchanged,
- replace the temperature row with `log(T_outer) - log(T_eff)`,
- replace the density row with `P_outer - P_ph`,
- compute `T_eff`, `g_surface`, and `P_ph` through the new helper functions,
- use the outer-cell opacity and EOS consistently.

In `src/numerics/structure_equations.jl`, add the smallest helper extraction needed if a local outer pressure or opacity accessor improves clarity.

Do not add a new pressure state variable.

**Step 4: Run test to verify it passes**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_boundary_conditions.jl")'
```

Expected: PASS with the new atmosphere-derived surface residual formulas.

**Step 5: Commit**

```bash
git add test/test_boundary_conditions.jl src/numerics/boundary_conditions.jl src/numerics/structure_equations.jl
git commit -m "feat: replace surface guess rows with atmosphere closure"
```

### Task 3: Replace The Outermost Transport Row And Re-Audit The Jacobian

**Files:**
- Create: `test/test_outer_transport_boundary.jl`
- Modify: `test/runtests.jl`
- Modify: `test/test_jacobian_fidelity_audit.jl`
- Modify: `src/numerics/residuals.jl`
- Modify: `src/numerics/jacobians.jl`
- Modify: `src/solvers/step_metrics.jl`

**Step 1: Write the failing test**

Create `test/test_outer_transport_boundary.jl`:

```julia
using Test
using ASTRA

@testset "outer transport boundary row" begin
    problem = ASTRA.build_toy_problem(n_cells = 12)
    model = ASTRA.initialize_state(problem)
    residual = ASTRA.assemble_structure_residual(problem, model)

    n = problem.grid.n_cells
    outer_block_rows = collect(ASTRA.interior_structure_row_range(n - 1))
    outer_transport_row = residual[outer_block_rows[end]]

    pressure_nm1 = ASTRA.cell_eos_state(problem, model, n - 1).pressure_dyn_cm2
    radius_surface_cm = exp(model.structure.log_radius_face_cm[end])
    luminosity_surface_erg_s = model.structure.luminosity_face_erg_s[end]
    teff_k = ASTRA.surface_effective_temperature_k(radius_surface_cm, luminosity_surface_erg_s)
    opacity_outer = ASTRA.cell_opacity_state(problem, model, n).opacity_cm2_g
    g_surface = ASTRA.surface_gravity_cgs(problem.parameters.mass_g, radius_surface_cm)
    p_ph = ASTRA.eddington_photospheric_pressure_dyn_cm2(g_surface, opacity_outer)
    nabla_nm1 = ASTRA.radiative_temperature_gradient(problem, model, n - 1)
    temperature_nm1 = exp(model.structure.log_temperature_cell_k[n - 1])

    expected = log(teff_k) - log(temperature_nm1) + nabla_nm1 * (log(p_ph) - log(pressure_nm1))
    @test outer_transport_row ≈ expected
end
```

Extend `test/test_jacobian_fidelity_audit.jl` with a transport-specific assertion that still expects the transport block to satisfy the current finite-difference tolerance after the outer-row change.

**Step 2: Run tests to verify they fail**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_outer_transport_boundary.jl"); include("test/test_jacobian_fidelity_audit.jl")'
```

Expected: FAIL because the last transport row still uses the generic interior cell-to-cell stencil.

**Step 3: Write minimal implementation**

In `src/numerics/residuals.jl`:

- keep geometry, hydrostatic, and luminosity rows unchanged,
- replace only the final transport row with the approved one-sided atmosphere match,
- keep the preceding interior transport rows unchanged.

In `src/numerics/jacobians.jl`:

- update the analytic/fill logic so the last transport row is compared against the correct row builder,
- keep the Jacobian basis in packed state unchanged,
- preserve the current fidelity-audit surface rather than bypassing it.

In `src/solvers/step_metrics.jl`:

- update any row-family labeling or weighting logic that assumes every transport row is a generic interior row,
- keep weighted diagnostics honest about the new outer boundary semantics.

**Step 4: Run tests to verify they pass**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_outer_transport_boundary.jl"); include("test/test_jacobian_fidelity_audit.jl")'
```

Expected: PASS with the new outer transport row and preserved Jacobian fidelity.

**Step 5: Commit**

```bash
git add test/test_outer_transport_boundary.jl test/runtests.jl test/test_jacobian_fidelity_audit.jl src/numerics/residuals.jl src/numerics/jacobians.jl src/solvers/step_metrics.jl
git commit -m "feat: add one-sided atmosphere transport row"
```

### Task 4: Prove The Boundary Hardening Improves Solver Behavior

**Files:**
- Modify: `test/test_default_newton_progress.jl`
- Modify: `test/test_convergence_basin.jl`
- Modify: `test/test_solver_progress_diagnostics.jl`
- Modify: `src/numerics/diagnostics.jl`

**Step 1: Write the failing test**

Extend the existing progress tests with atmosphere-specific evidence:

```julia
@testset "default newton progress with atmosphere boundary" begin
    problem = ASTRA.build_toy_problem(n_cells = 12)
    result = ASTRA.solve_structure(problem)

    @test any(note -> occursin("atmosphere", lowercase(note)) || occursin("surface", lowercase(note)), result.diagnostics.notes)
    @test result.diagnostics.weighted_residual_norm <= result.diagnostics.initial_weighted_residual_norm
end
```

In `test/test_convergence_basin.jl`, add one assertion that the final dominant weighted residual family is no longer the old fixed-density surface row if the diagnostics expose row-family summaries. If not, add the smallest diagnostics extension needed to support that assertion.

**Step 2: Run tests to verify they fail**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_default_newton_progress.jl"); include("test/test_convergence_basin.jl"); include("test/test_solver_progress_diagnostics.jl")'
```

Expected: FAIL because diagnostics do not yet describe the new atmosphere-boundary behavior explicitly.

**Step 3: Write minimal implementation**

In `src/numerics/diagnostics.jl`:

- add the smallest structured notes or row-family summary needed to report the atmosphere boundary honestly,
- do not hide raw residual norms,
- keep the new reporting specific rather than generic.

Update the tests to match the exact supported diagnostics shape, not a speculative future API.

**Step 4: Run tests to verify they pass**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_default_newton_progress.jl"); include("test/test_convergence_basin.jl"); include("test/test_solver_progress_diagnostics.jl")'
```

Expected: PASS with honest atmosphere-aware progress reporting.

**Step 5: Commit**

```bash
git add test/test_default_newton_progress.jl test/test_convergence_basin.jl test/test_solver_progress_diagnostics.jl src/numerics/diagnostics.jl
git commit -m "test: validate atmosphere boundary solver behavior"
```

### Task 5: Add The Canonical Atmosphere Physics Page And Honest Website Updates

**Files:**
- Create: `docs/website/physics/atmosphere-and-photosphere.md`
- Modify: `docs/website/physics/overview.md`
- Modify: `docs/website/physics/boundary-conditions.md`
- Modify: `docs/website/methods/boundary-condition-realization.md`
- Modify: `docs/website/methods/residual-assembly.md`
- Modify: `docs/website/methods/overview.md`
- Modify: `docs/website/development/progress-summary.md`
- Modify: `docs/website/development/changelog.md`
- Modify: `docs/website/development/checklists/solar-first-lane.md`
- Modify: `docs/website/myst.yml`
- Modify: `test/test_docs_structure.jl`

**Step 1: Write the failing test**

Extend `test/test_docs_structure.jl` with assertions that:

- the new atmosphere physics page exists,
- it is present in the docs nav,
- it includes a phases section,
- it includes a checklist section.

**Step 2: Run test to verify it fails**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_docs_structure.jl")'
```

Expected: FAIL because the atmosphere page and nav entries do not exist yet.

**Step 3: Write minimal implementation**

Create `docs/website/physics/atmosphere-and-photosphere.md` with:

- photosphere definition and `tau = 2/3`,
- Eddington-grey `T_eff` and `P_ph` relations,
- ASTRA's current Phase 1 implementation,
- planned phases 2 and 3,
- a detailed checklist for scientific meaning, implementation status, validation status, and deferred work.

Update the linked physics, methods, and development pages so the new page becomes the canonical atmosphere reference.

**Step 4: Run docs validation**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_docs_structure.jl")'
cd /Users/anna/projects/julia-dev/astra/docs/website && myst build --site --html --strict
```

Expected: both commands PASS and the atmosphere page renders cleanly in the site.

**Step 5: Commit**

```bash
git add docs/website/physics/atmosphere-and-photosphere.md docs/website/physics/overview.md docs/website/physics/boundary-conditions.md docs/website/methods/boundary-condition-realization.md docs/website/methods/residual-assembly.md docs/website/methods/overview.md docs/website/development/progress-summary.md docs/website/development/changelog.md docs/website/development/checklists/solar-first-lane.md docs/website/myst.yml test/test_docs_structure.jl
git commit -m "docs: add atmosphere boundary physics guide"
```

### Task 6: Run Full Required Verification

**Files:**
- No code changes expected.

**Step 1: Run the required command set**

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

- all required commands PASS,
- Jacobian fidelity remains within the current audit tolerances,
- docs build cleanly,
- the package test suite stays green with the new atmosphere boundary semantics.

**Step 2: Commit verification-only follow-up if needed**

If code or docs had to change during verification, make one final focused commit describing the exact fix. If no changes were needed, do not create an extra commit.
