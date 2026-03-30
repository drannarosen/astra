# Transport / Outer-Boundary Hardening Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Isolate whether ASTRA's current transport-dominated bottleneck is interior-transport-local or outer-boundary-local, then harden the current classical Newton pipeline with the smallest transport-focused conditioning and domain safeguards that preserve residual ownership.

**Architecture:** This slice is deliberately narrower than a generic conditioning rewrite. It first splits the current `transport` diagnostics into interior and outer pieces, then hardens the solver metrics and trial-step domain guards around the one-sided outer transport interface without changing ASTRA's packed basis, public ownership contract, or broad globalization policy. The residual definition remains canonical unless the new evidence shows a structural mismatch that cannot be addressed solver-side.

**Tech Stack:** Julia 1.12, stdlib `Test`, current ASTRA numerics/solver stack, artifact TOML/plain-text validation bundle, MystMD docs, @test-driven-development, @scientific-collaborator-mode, @structural-mismatch-stop-rule, @scientific-verification-gate

---

## Design Notes

### Source-backed strategy

- MESA uses layered conditioning rather than one global scaling knob:
  - per-variable correction scaling through `x_scale`,
  - equation-local normalization inside the residual assembly,
  - and domain-aware correction damping and clipping.
- ASTRA already gets part of that conditioning from its solve basis `[\ln R, L, \ln T, \ln \rho]`, so the nearest ASTRA analogue is not "copy `x_scale` everywhere."
- The next ASTRA slice should therefore:
  - split the current transport diagnostics into interior and outer pieces,
  - add transport-local reference scales on the solver-metric side first,
  - add a small domain-aware outer-boundary guard tied to linear surface luminosity,
  - and only then decide whether any residual-level reformulation is justified.

### Scientific stop rules

- If the split transport artifacts show the dominant signal is **interior transport** rather than **outer transport**, stop before any boundary-specific reformulation and record that the next bottleneck is transport-helper-local rather than boundary-local.
- If the split artifacts show the dominant signal is **surface pressure** or another family after the metric-local changes, stop and explain that the earlier transport interpretation no longer holds.
- Do not widen scope into adaptive regularization, trust-region logic, new solve variables, composition evolution, or a new atmosphere state block.

### Validation target for this slice

Success for this slice does **not** mean full convergence. It means the artifact bundle becomes more discriminating and the repeated failure signature becomes scientifically sharper.

Minimum success criteria:

- validation payloads record `interior_transport` and `outer_transport` merit contributions explicitly,
- the manifest and dated note can distinguish which transport subfamily dominates,
- transport row weights are no longer hard-coded to `1.0`,
- surface-luminosity-invalid trial steps are clipped before the one-sided outer transport row can hide them behind `clip_positive`,
- and the updated bundle tells us whether outer-boundary-local hardening actually weakens the previous dominant signature.

### Boundary documentation refinements to fold in during this slice

The current `Boundary Conditions` page is already scientifically useful, but the latest review surfaced three improvements that fit this slice without widening architecture:

- separate boundary **contract** language from current **implementation** language more explicitly,
- state boundary **ownership** directly: boundary rows own the edge equations of the global residual, but they do not own EOS, opacity, or atmosphere microphysics internals,
- add short **boundary validity checks** that name what counts as a numerically acceptable boundary realization in the current lane.

Those are documentation hardening tasks, not a license to introduce a full atmosphere-provider interface in this slice. A formal replaceable atmosphere-provider contract is still deferred until the transport-split evidence proves that boundary architecture, rather than local transport physics or derivative quality, is the sharper next bottleneck.

### Task 1: Split Transport Diagnostics Into Interior And Outer Families

**Files:**
- Create: `test/test_transport_row_family_diagnostics.jl`
- Modify: `test/runtests.jl`
- Modify: `src/foundation/types.jl`
- Modify: `src/solvers/step_metrics.jl`
- Modify: `src/validation/armijo_merit_validation.jl`

**Step 1: Write the failing test**

Create `test/test_transport_row_family_diagnostics.jl`:

```julia
@testset "transport row family diagnostics" begin
    problem = ASTRA.build_toy_problem(n_cells = 8)
    model = ASTRA.initialize_state(problem)
    residual = ASTRA.assemble_structure_residual(problem, model)
    summary = ASTRA.Solvers.row_family_merit_summary(problem, model, residual)

    @test summary.transport ≈ summary.interior_transport + summary.outer_transport
    @test summary.total ≈
          summary.center +
          summary.geometry +
          summary.hydrostatic +
          summary.luminosity +
          summary.transport +
          summary.surface
    @test summary.dominant_family in (
        :center,
        :geometry,
        :hydrostatic,
        :luminosity,
        :interior_transport,
        :outer_transport,
        :surface,
    )
end
```

**Step 2: Run test to verify it fails**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_transport_row_family_diagnostics.jl")'
```

Expected: FAIL because `RowFamilyMeritSummary` does not yet expose `interior_transport` and `outer_transport`.

**Step 3: Write minimal implementation**

In `src/foundation/types.jl`, extend `RowFamilyMeritSummary`:

```julia
struct RowFamilyMeritSummary
    center::Float64
    geometry::Float64
    hydrostatic::Float64
    luminosity::Float64
    interior_transport::Float64
    outer_transport::Float64
    transport::Float64
    surface::Float64
    total::Float64
    dominant_family::Symbol
end
```

In `src/solvers/step_metrics.jl`, split the family accumulation:

```julia
interior_transport = 0.0
outer_transport = 0.0

for k in 1:(n - 1)
    row_range = interior_structure_row_range(k)
    row = first(row_range)
    if k == n - 1
        outer_transport += _family_merit(weighted_residual, (row + 3):(row + 3))
    else
        interior_transport += _family_merit(weighted_residual, (row + 3):(row + 3))
    end
end

transport = interior_transport + outer_transport
family_values = (
    center,
    geometry,
    hydrostatic,
    luminosity,
    interior_transport,
    outer_transport,
    surface,
)
family_names = (
    :center,
    :geometry,
    :hydrostatic,
    :luminosity,
    :interior_transport,
    :outer_transport,
    :surface,
)
```

In `src/validation/armijo_merit_validation.jl`, write the new split fields anywhere a `RowFamilyMeritSummary` is serialized.

**Step 4: Run test to verify it passes**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_transport_row_family_diagnostics.jl")'
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_armijo_merit_validation_payload.jl"); include("test/test_armijo_merit_validation_runner.jl")'
```

Expected: PASS.

**Step 5: Commit**

```bash
git add test/test_transport_row_family_diagnostics.jl test/runtests.jl src/foundation/types.jl src/solvers/step_metrics.jl src/validation/armijo_merit_validation.jl
git commit -m "feat: split transport row-family diagnostics"
```

### Task 2: Surface Split Transport Evidence In Validation Artifacts

**Files:**
- Create: `test/test_transport_validation_artifacts.jl`
- Modify: `test/runtests.jl`
- Modify: `src/foundation/types.jl`
- Modify: `src/validation/armijo_merit_validation.jl`
- Modify: `scripts/run_armijo_merit_validation.jl`

**Step 1: Write the failing test**

Create `test/test_transport_validation_artifacts.jl`:

```julia
@testset "transport validation artifacts" begin
    mktempdir() do tmpdir
        bundle = ASTRA.run_armijo_merit_validation_suite(tmpdir)
        manifest = read(bundle.manifest_path, String)
        payload = read(first(bundle.payload_paths), String)

        @test occursin("accepted_transport_dominant_family", manifest)
        @test occursin("best_rejected_transport_dominant_family", manifest)
        @test occursin("row_family_merit.interior_transport", payload)
        @test occursin("row_family_merit.outer_transport", payload)
    end
end
```

**Step 2: Run test to verify it fails**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_transport_validation_artifacts.jl")'
```

Expected: FAIL because the manifest and payload writers do not yet surface the split transport evidence.

**Step 3: Write minimal implementation**

In `src/foundation/types.jl`, extend `ArmijoMeritValidationPayload` only if you need a small explicit transport-dominance summary:

```julia
struct ArmijoMeritValidationPayload
    # existing fields...
    accepted_transport_dominant_family::Union{Nothing,Symbol}
end
```

In `src/validation/armijo_merit_validation.jl`:

- write `interior_transport` and `outer_transport` in `_write_armijo_merit_validation_row_family_summary`,
- record `accepted_transport_dominant_family` by inspecting the accepted trial's split row-family summary,
- record `best_rejected_transport_dominant_family` similarly in the manifest,
- keep the old aggregate `transport` field so existing comparisons stay readable.

In `scripts/run_armijo_merit_validation.jl`, keep the existing suite matrix unchanged.

**Step 4: Run test to verify it passes**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_transport_validation_artifacts.jl")'
```

Expected: PASS.

**Step 5: Commit**

```bash
git add test/test_transport_validation_artifacts.jl test/runtests.jl src/foundation/types.jl src/validation/armijo_merit_validation.jl scripts/run_armijo_merit_validation.jl
git commit -m "feat: enrich transport validation artifacts"
```

### Task 3: Add Explicit Transport Reference Scales To Solver Metrics

**Files:**
- Create: `test/test_transport_row_weights.jl`
- Modify: `test/runtests.jl`
- Modify: `src/solvers/step_metrics.jl`
- Modify: `docs/website/methods/nonlinear-step-metrics-and-globalization.md`
- Modify: `docs/website/methods/linear-solves-and-scaling.md`

**Step 1: Write the failing test**

Create `test/test_transport_row_weights.jl`:

```julia
@testset "transport row weights" begin
    problem = ASTRA.build_toy_problem(n_cells = 8)
    model = ASTRA.initialize_state(problem)
    weights = ASTRA.Solvers.residual_row_weights(problem, model)

    n = problem.grid.n_cells
    interior_transport_row = first(ASTRA.interior_structure_row_range(1)) + 3
    outer_transport_row = first(ASTRA.interior_structure_row_range(n - 1)) + 3

    @test weights[interior_transport_row] != 1.0
    @test weights[outer_transport_row] != 1.0
    @test weights[interior_transport_row] > 0.0
    @test weights[outer_transport_row] > 0.0
end
```

**Step 2: Run test to verify it fails**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_transport_row_weights.jl")'
```

Expected: FAIL because transport row weights are currently hard-coded to `1.0`.

**Step 3: Write minimal implementation**

In `src/solvers/step_metrics.jl`, add explicit transport reference-scale helpers:

```julia
function _interior_transport_reference_scale(problem::StructureProblem, model::StellarModel, k::Int)
    state = model.structure
    pressure_k = cell_eos_state(problem, model, k).pressure_dyn_cm2
    pressure_kp1 = cell_eos_state(problem, model, k + 1).pressure_dyn_cm2
    delta_log_temperature = state.log_temperature_cell_k[k + 1] - state.log_temperature_cell_k[k]
    delta_log_pressure = log(clip_positive(pressure_kp1)) - log(clip_positive(pressure_k))
    gradient_term = radiative_temperature_gradient(problem, model, k) * delta_log_pressure
    return max(abs(delta_log_temperature), abs(gradient_term), 1.0)
end

function _outer_transport_reference_scale(problem::StructureProblem, model::StellarModel, k::Int)
    # same pattern, but use the photospheric face temperature/pressure targets
end
```

Replace the current unit transport weights:

```julia
weights[first(row_range) + 3] = _scale_weight(
    k == n - 1 ?
    _outer_transport_reference_scale(problem, model, k) :
    _interior_transport_reference_scale(problem, model, k),
)
```

Do **not** change the residual formula in this task. This is solver-metric hardening only.

**Step 4: Run test to verify it passes**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_transport_row_weights.jl")'
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_solver_progress_diagnostics.jl"); include("test/test_default_newton_progress.jl")'
```

Expected: PASS.

**Step 5: Commit**

```bash
git add test/test_transport_row_weights.jl test/runtests.jl src/solvers/step_metrics.jl docs/website/methods/nonlinear-step-metrics-and-globalization.md docs/website/methods/linear-solves-and-scaling.md
git commit -m "feat: add transport-local solver metric scaling"
```

### Task 4: Add An Outer-Boundary Luminosity Domain Guard

**Files:**
- Create: `test/test_outer_boundary_domain_guard.jl`
- Modify: `test/runtests.jl`
- Modify: `src/solvers/nonlinear_solvers.jl`
- Modify: `src/numerics/diagnostics.jl`
- Modify: `docs/website/methods/nonlinear-newton-and-backtracking.md`

**Step 1: Write the failing test**

Create `test/test_outer_boundary_domain_guard.jl`:

```julia
@testset "outer boundary domain guard" begin
    problem = ASTRA.build_toy_problem(n_cells = 8)
    model = ASTRA.initialize_state(problem)
    update = zeros(length(ASTRA.pack_state(model.structure)))
    surface_luminosity_index = problem.grid.n_cells + 1 + (problem.grid.n_cells + 1)
    update[surface_luminosity_index] = -10.0 * abs(model.structure.luminosity_face_erg_s[end])

    limited = ASTRA.Solvers.limit_outer_boundary_domain(problem, model, update)
    trial_vector = ASTRA.pack_state(model.structure) .+ limited.update
    trial_structure = ASTRA.unpack_state(model.structure, trial_vector)

    @test limited.factor < 1.0
    @test trial_structure.luminosity_face_erg_s[end] > 0.0
end
```

**Step 2: Run test to verify it fails**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_outer_boundary_domain_guard.jl")'
```

Expected: FAIL because ASTRA does not yet expose an outer-boundary domain limiter.

**Step 3: Write minimal implementation**

In `src/solvers/nonlinear_solvers.jl`, add a small helper:

```julia
function limit_outer_boundary_domain(
    problem::StructureProblem,
    model::StellarModel,
    update::AbstractVector{<:Real},
)
    base_vector = pack_state(model.structure)
    factor = 1.0
    surface_luminosity = model.structure.luminosity_face_erg_s[end]
    surface_luminosity_index = 2 * (problem.grid.n_cells + 1)
    delta_surface_luminosity = Float64(update[surface_luminosity_index])

    if surface_luminosity + delta_surface_luminosity <= 0.0
        factor = min(factor, 0.9 * surface_luminosity / abs(delta_surface_luminosity))
    end

    return (factor = factor, update = factor .* Float64.(update))
end
```

Apply it after `limit_weighted_correction(...)` and before the damping loop. Add a diagnostics note when it activates. Keep the guard narrowly tied to the one-sided outer transport boundary through the surface luminosity owner; do not broaden this into a general positivity framework in this slice.

As a follow-up check inside this task, make sure the note text is boundary-ownership-explicit rather than generic. The note should make it clear that this is a solver-side domain guard protecting the one-sided outer transport trial, not a redefinition of the physical surface closure.

**Step 4: Run test to verify it passes**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_outer_boundary_domain_guard.jl")'
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_solver_progress_diagnostics.jl"); include("test/test_convergence_basin.jl")'
```

Expected: PASS.

**Step 5: Commit**

```bash
git add test/test_outer_boundary_domain_guard.jl test/runtests.jl src/solvers/nonlinear_solvers.jl src/numerics/diagnostics.jl docs/website/methods/nonlinear-newton-and-backtracking.md
git commit -m "feat: guard one-sided outer transport trials"
```

### Task 5: Rebuild The Validation Bundle And Refresh The Website Record

**Files:**
- Modify: `docs/website/development/progress-summary.md`
- Create: `docs/website/development/transport-outer-boundary-hardening-2026-03-30.md`
- Modify: `docs/website/physics/boundary-conditions.md`
- Modify: `docs/website/methods/residual-assembly.md`
- Modify: `docs/website/physics/stellar-structure/energy-transport.md`
- Modify: `docs/website/methods/mesa-reference/solver-scaling.md`
- Create: `artifacts/validation/2026-03-30-transport-outer-boundary-hardening/`
- Modify: `test/test_docs_structure.jl`

**Step 1: Write the failing test**

In `test/test_docs_structure.jl`, add assertions that:

```julia
@test occursin(
    "transport-outer-boundary-hardening-2026-03-30",
    read("docs/website/development/progress-summary.md", String),
)
@test occursin(
    "interior_transport",
    read("docs/website/methods/residual-assembly.md", String),
)
@test occursin(
    "equation-local normalization",
    read("docs/website/methods/mesa-reference/solver-scaling.md", String),
)
@test occursin(
    "Boundary rows own the edge equations of the global residual",
    read("docs/website/physics/boundary-conditions.md", String),
)
@test occursin(
    "Boundary validity checks",
    read("docs/website/physics/boundary-conditions.md", String),
)
```

**Step 2: Run test to verify it fails**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_docs_structure.jl")'
```

Expected: FAIL because the new dated note and updated methods wording are not present yet.

**Step 3: Write minimal implementation**

Run the updated validation suite:

```bash
~/.juliaup/bin/julia --project=. scripts/run_armijo_merit_validation.jl artifacts/validation/2026-03-30-transport-outer-boundary-hardening
```

Then write:

- a new dated note at `docs/website/development/transport-outer-boundary-hardening-2026-03-30.md`,
- a short progress summary entry linking the artifact directory and stating whether `interior_transport` or `outer_transport` dominated,
- an updated `docs/website/physics/boundary-conditions.md` page that:
  - separates current contract from current implementation more cleanly,
  - adds one explicit boundary-ownership sentence,
  - and adds a short `Boundary validity checks` section without promising a broader BC architecture than ASTRA actually owns today,
- methods-page updates that distinguish:
  - code-backed facts,
  - measured transport-split results,
  - and any remaining hypothesis about boundary-local vs helper-local trouble.

If the refreshed artifact bundle does **not** show an outer-boundary-local signature, say so directly and update the dated note to stop short of claiming boundary-local causality.

**Step 4: Run test to verify it passes**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_armijo_merit_validation_runner.jl"); include("test/test_docs_structure.jl")'
cd /Users/anna/projects/julia-dev/astra/docs/website && myst build --site --html --strict
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_default_newton_progress.jl"); include("test/test_convergence_basin.jl")'
```

Expected: PASS.

**Step 5: Commit**

```bash
git add artifacts/validation/2026-03-30-transport-outer-boundary-hardening docs/website/development/progress-summary.md docs/website/development/transport-outer-boundary-hardening-2026-03-30.md docs/website/physics/boundary-conditions.md docs/website/methods/residual-assembly.md docs/website/physics/stellar-structure/energy-transport.md docs/website/methods/mesa-reference/solver-scaling.md test/test_docs_structure.jl
git commit -m "docs: record transport boundary hardening evidence"
```

## Final Verification

Run these before claiming the slice is complete:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_transport_row_family_diagnostics.jl"); include("test/test_transport_validation_artifacts.jl"); include("test/test_transport_row_weights.jl"); include("test/test_outer_boundary_domain_guard.jl")'
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_outer_transport_boundary.jl"); include("test/test_solver_progress_diagnostics.jl")'
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_default_newton_progress.jl"); include("test/test_convergence_basin.jl")'
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_jacobian_fidelity_audit.jl")'
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_docs_structure.jl")'
cd /Users/anna/projects/julia-dev/astra/docs/website && myst build --site --html --strict
~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
```

## Evidence To Report During Execution

After each meaningful run, report:

- whether `interior_transport` or `outer_transport` is dominant,
- accepted step count,
- rejected trial count,
- final raw residual norm,
- final weighted residual norm,
- final merit,
- whether regularized fallback was used,
- pass/fail against the task-specific criterion,
- what the numbers do not prove,
- and the next concrete action.
