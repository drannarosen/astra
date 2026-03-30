# Transport Hotspot Diagnostics Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Tighten ASTRA's transport-row ownership and surface row-level hotspot evidence so the next transport hardening decision is based on measured near-surface versus deep-interior behavior, not on a blended `interior_transport` bucket.

**Architecture:** This slice is diagnostic-first and behavior-preserving. It introduces one canonical helper for transport-row terms, then builds transport hotspot summaries and artifact output on top of that helper. The residual definition, packed basis, boundary ownership, and globalization policy stay unchanged unless the new hotspot evidence falsifies the current diagnosis. The current measured default-12 evidence says helper derivatives are already locally correct, so this slice does not widen into new transport physics or a controller rewrite.

**Tech Stack:** Julia 1.12, stdlib `Test`, current ASTRA numerics/solver stack, artifact TOML/plain-text validation bundle, MystMD docs, @test-driven-development, @scientific-collaborator-mode, @subagent-driven-development, @structural-mismatch-stop-rule

---

## Design Notes

### Why this slice is next

- The committed `2026-03-30` transport hardening bundle already shows a mixed signal:
  - `default-12`, `cells-12`, `cells-16`, `cells-24`, and `perturb-a1e-6-case-03` are `interior_transport`-dominant,
  - `cells-6` and `cells-8` are `outer_transport`-dominant,
  - and two perturbation cases are `surface`-dominant.
- A targeted solved-state diagnostic on the current `default-12` result shows that transport helper sensitivities already match finite differences essentially exactly across the whole transport family, so transport helper derivative formulas are **not** the current sharpest blocker.
- That same solved-state diagnostic shows the weighted transport residual is concentrated in the near-surface rows:
  - the final interior transport row at `k = n - 2`,
  - and the one-sided outer transport row at `k = n - 1`.
- The current `interior_transport` bucket is therefore too coarse to support the next scientific decision by itself.

### Scientific stop rules

- If the new hotspot summary shows the dominant transport contribution is deep interior rather than near-surface, stop before any boundary-adjacent hardening and record that the problem is not surface-local.
- If the hotspot summary shows the `surface` family, not transport, is the repeated dominant row after the new instrumentation lands, stop and explain that the transport-first interpretation no longer holds.
- Do not widen scope into adaptive regularization, trust-region logic, new solve variables, or a new atmosphere-provider interface in this slice.

### Validation target for this slice

Success for this slice does **not** mean convergence. It means ASTRA can now answer these questions directly from a payload:

- Which single transport row carries the largest weighted contribution?
- Is that hotspot deep interior, surface-adjacent interior, or outer?
- What are the row terms there: `ΔlogT`, `nabla * ΔlogP`, `nabla`, and `ΔlogP`?

Minimum success criteria:

- transport row decomposition has one canonical code owner,
- residual assembly and transport row weighting use that shared owner,
- validation payloads record a transport hotspot summary for accepted and best-rejected states,
- the manifest and dated note can distinguish near-surface hotspot concentration from broad interior transport trouble,
- and the updated bundle sharpens the next hardening decision without changing solver ownership.

### Task 1: Create A Canonical Transport Row-Term Helper

**Files:**
- Create: `test/test_transport_row_terms.jl`
- Modify: `test/runtests.jl`
- Modify: `src/numerics/structure_equations.jl`
- Modify: `src/numerics/residuals.jl`
- Modify: `src/solvers/step_metrics.jl`
- Modify: `test/test_outer_transport_boundary.jl`
- Modify: `test/test_transport_row_weights.jl`

**Step 1: Write the failing test**

Create `test/test_transport_row_terms.jl`:

```julia
@testset "transport row terms" begin
    problem = ASTRA.build_toy_problem(n_cells = 8)
    model = ASTRA.initialize_state(problem)
    n = problem.grid.n_cells

    interior = ASTRA.transport_row_terms(problem, model, 2)
    @test interior.location == :interior
    @test !interior.is_outer
    @test interior.residual ≈ interior.delta_log_temperature + interior.gradient_term
    @test interior.gradient_term ≈ interior.nabla_transport * interior.delta_log_pressure

    outer = ASTRA.transport_row_terms(problem, model, n - 1)
    @test outer.location == :outer
    @test outer.is_outer
    @test outer.residual ≈ outer.delta_log_temperature + outer.gradient_term
    @test outer.gradient_term ≈ outer.nabla_transport * outer.delta_log_pressure
end
```

**Step 2: Run test to verify it fails**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_transport_row_terms.jl")'
```

Expected: FAIL because `ASTRA.transport_row_terms` does not exist yet.

**Step 3: Write minimal implementation**

In `src/numerics/structure_equations.jl`, add:

```julia
function transport_row_terms(problem::StructureProblem, model::StellarModel, k::Int)
    state = model.structure
    n = problem.grid.n_cells
    outer = (k == n - 1)
    pressure_k_dyn_cm2 = cell_eos_state(problem, model, k).pressure_dyn_cm2
    nabla_transport = radiative_temperature_gradient(problem, model, k)

    if outer
        radius_surface_cm = exp(state.log_radius_face_cm[end])
        luminosity_surface_erg_s = state.luminosity_face_erg_s[end]
        face_temperature_k = surface_effective_temperature_k(
            radius_surface_cm,
            luminosity_surface_erg_s,
        )
        surface_gravity_cgs_value = surface_gravity_cgs(problem.parameters.mass_g, radius_surface_cm)
        opacity_outer_cm2_g = cell_opacity_state(problem, model, n).opacity_cm2_g
        face_pressure_dyn_cm2 = eddington_photospheric_pressure_dyn_cm2(
            surface_gravity_cgs_value,
            opacity_outer_cm2_g,
        )
        delta_log_temperature = positive_log(face_temperature_k) - state.log_temperature_cell_k[k]
        delta_log_pressure =
            log(clip_positive(face_pressure_dyn_cm2)) - log(clip_positive(pressure_k_dyn_cm2))
        gradient_term = nabla_transport * delta_log_pressure
        return (
            cell_index = k,
            location = :outer,
            is_outer = true,
            delta_log_temperature = delta_log_temperature,
            delta_log_pressure = delta_log_pressure,
            nabla_transport = nabla_transport,
            gradient_term = gradient_term,
            residual = delta_log_temperature + gradient_term,
        )
    end

    pressure_kp1_dyn_cm2 = cell_eos_state(problem, model, k + 1).pressure_dyn_cm2
    delta_log_temperature = state.log_temperature_cell_k[k + 1] - state.log_temperature_cell_k[k]
    delta_log_pressure =
        log(clip_positive(pressure_kp1_dyn_cm2)) - log(clip_positive(pressure_k_dyn_cm2))
    gradient_term = nabla_transport * delta_log_pressure
    return (
        cell_index = k,
        location = :interior,
        is_outer = false,
        delta_log_temperature = delta_log_temperature,
        delta_log_pressure = delta_log_pressure,
        nabla_transport = nabla_transport,
        gradient_term = gradient_term,
        residual = delta_log_temperature + gradient_term,
    )
end
```

Then route `src/numerics/residuals.jl` and `src/solvers/step_metrics.jl` through that helper instead of recomputing transport terms inline.

**Step 4: Run tests to verify they pass**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_transport_row_terms.jl")'
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_outer_transport_boundary.jl"); include("test/test_transport_row_weights.jl")'
```

Expected: PASS.

**Step 5: Commit**

```bash
git add test/test_transport_row_terms.jl test/runtests.jl src/numerics/structure_equations.jl src/numerics/residuals.jl src/solvers/step_metrics.jl test/test_outer_transport_boundary.jl test/test_transport_row_weights.jl
git commit -m "feat: add canonical transport row terms"
```

### Task 2: Add Transport Hotspot Summaries To Solver Diagnostics

**Files:**
- Create: `test/test_transport_hotspot_diagnostics.jl`
- Modify: `test/runtests.jl`
- Modify: `src/foundation/types.jl`
- Modify: `src/solvers/step_metrics.jl`
- Modify: `test/test_solver_progress_diagnostics.jl`

**Step 1: Write the failing test**

Create `test/test_transport_hotspot_diagnostics.jl`:

```julia
@testset "transport hotspot diagnostics" begin
    problem = ASTRA.build_toy_problem(n_cells = 8)
    model = ASTRA.initialize_state(problem)
    residual = ASTRA.assemble_structure_residual(problem, model)
    weights = ASTRA.Solvers.residual_row_weights(problem, model)

    hotspot = ASTRA.Solvers.transport_hotspot_summary(problem, model, residual; row_weights = weights)

    @test hotspot.present
    @test hotspot.cell_index in 1:(problem.grid.n_cells - 1)
    @test hotspot.location in (:interior, :outer)
    @test hotspot.weighted_contribution ≈ hotspot.row_weight * hotspot.raw_residual
    @test hotspot.raw_residual ≈ hotspot.delta_log_temperature + hotspot.gradient_term
    @test hotspot.gradient_term ≈ hotspot.nabla_transport * hotspot.delta_log_pressure
end
```

**Step 2: Run test to verify it fails**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_transport_hotspot_diagnostics.jl")'
```

Expected: FAIL because no transport hotspot summary exists yet.

**Step 3: Write minimal implementation**

In `src/foundation/types.jl`, add:

```julia
struct TransportHotspotSummary
    present::Bool
    cell_index::Int
    location::Symbol
    row_index::Int
    raw_residual::Float64
    row_weight::Float64
    weighted_contribution::Float64
    delta_log_temperature::Float64
    delta_log_pressure::Float64
    nabla_transport::Float64
    gradient_term::Float64
end
```

In `src/solvers/step_metrics.jl`, add `transport_hotspot_summary(...)` that scans only transport rows, uses `transport_row_terms(...)`, and returns the largest `abs(weight * residual)` transport contribution.

Wire the summary into the accepted-trial diagnostics in the smallest possible way, without changing solver acceptance.

**Step 4: Run tests to verify they pass**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_transport_hotspot_diagnostics.jl"); include("test/test_solver_progress_diagnostics.jl")'
```

Expected: PASS.

**Step 5: Commit**

```bash
git add test/test_transport_hotspot_diagnostics.jl test/runtests.jl src/foundation/types.jl src/solvers/step_metrics.jl test/test_solver_progress_diagnostics.jl
git commit -m "feat: add transport hotspot diagnostics"
```

### Task 3: Surface Transport Hotspots In Validation Artifacts

**Files:**
- Create: `test/test_transport_hotspot_artifacts.jl`
- Modify: `test/runtests.jl`
- Modify: `src/foundation/types.jl`
- Modify: `src/validation/armijo_merit_validation.jl`
- Modify: `scripts/run_armijo_merit_validation.jl`

**Step 1: Write the failing test**

Create `test/test_transport_hotspot_artifacts.jl`:

```julia
@testset "transport hotspot artifacts" begin
    mktempdir() do tmpdir
        bundle = ASTRA.run_armijo_merit_validation_suite(tmpdir)
        manifest = read(bundle.manifest_path, String)
        payload = read(first(bundle.payload_paths), String)

        @test occursin("accepted_transport_hotspot_location", manifest)
        @test occursin("accepted_transport_hotspot_cell_index", manifest)
        @test occursin("accepted_transport_hotspot.location", payload)
        @test occursin("accepted_transport_hotspot.gradient_term", payload)
        @test occursin("best_rejected_transport_hotspot.location", payload)
    end
end
```

**Step 2: Run test to verify it fails**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_transport_hotspot_artifacts.jl")'
```

Expected: FAIL because the bundle does not yet serialize transport hotspot summaries.

**Step 3: Write minimal implementation**

In `src/foundation/types.jl`, extend the payload types only as needed to carry accepted and best-rejected transport hotspot summaries.

In `src/validation/armijo_merit_validation.jl`:

- serialize the new hotspot summaries in payload TOML,
- add compact manifest fields for accepted hotspot location and cell index,
- keep the existing transport-family summary intact.

Do not change the validation matrix in `scripts/run_armijo_merit_validation.jl`.

**Step 4: Run tests to verify they pass**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_transport_hotspot_artifacts.jl")'
```

Expected: PASS.

**Step 5: Commit**

```bash
git add test/test_transport_hotspot_artifacts.jl test/runtests.jl src/foundation/types.jl src/validation/armijo_merit_validation.jl scripts/run_armijo_merit_validation.jl
git commit -m "feat: record transport hotspot artifacts"
```

### Task 4: Refresh The Validation Bundle And Docs

**Files:**
- Modify: `test/test_docs_structure.jl`
- Modify: `docs/website/development/transport-outer-boundary-hardening-2026-03-30.md`
- Modify: `docs/website/development/progress-summary.md`
- Create: `artifacts/validation/2026-03-30-transport-hotspot-diagnostics/`

**Step 1: Write the failing doc-structure test**

Add expectations in `test/test_docs_structure.jl` for the dated note to mention:

- `transport hotspot`,
- `cell index`,
- and `surface-adjacent` or equivalent wording if the refreshed bundle supports that interpretation.

**Step 2: Run test to verify it fails**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_docs_structure.jl")'
```

Expected: FAIL until the dated note is refreshed.

**Step 3: Write minimal implementation**

- rerun the validation suite into `artifacts/validation/2026-03-30-transport-hotspot-diagnostics/`,
- update the dated note with the new measured hotspot evidence,
- update `progress-summary.md` with the new diagnosis and next-step recommendation.

Be explicit in the note about:

- what is measured from the artifact bundle,
- what remains hypothesis,
- and whether the hotspot is deep interior, surface-adjacent interior, or outer.

**Step 4: Run verification**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_docs_structure.jl")'
cd /Users/anna/projects/julia-dev/astra/docs/website && myst build --site --html --strict
```

Expected: PASS.

**Step 5: Commit**

```bash
git add test/test_docs_structure.jl docs/website/development/transport-outer-boundary-hardening-2026-03-30.md docs/website/development/progress-summary.md artifacts/validation/2026-03-30-transport-hotspot-diagnostics
git commit -m "docs: record transport hotspot evidence"
```
