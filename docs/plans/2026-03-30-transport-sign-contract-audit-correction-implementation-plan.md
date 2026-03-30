# Transport Sign-Contract Audit And Correction Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Audit ASTRA's transport row sign contract against the documented `nabla` meaning, and if the mismatch is confirmed, land the smallest canonical sign correction before any further transport hardening.

**Architecture:** This slice is a structural-mismatch audit with a candidate correction carried in the same plan. The canonical owner is the transport-row decomposition helper and the residual row that consumes it. The packed basis, public ownership contract, surface-closure ownership, and solver globalization policy stay unchanged. The red tests decide whether the candidate correction is real or whether the docs, not the row, are inconsistent.

**Tech Stack:** Julia 1.12, stdlib `Test`, current ASTRA numerics/solver stack, artifact TOML/plain-text validation bundle, MystMD docs, @test-driven-development, @scientific-collaborator-mode, @structural-mismatch-stop-rule, @scientific-verification-gate

---

## Design Notes

### Source-backed problem statement

- ASTRA documents `nabla = d log(T) / d log(P)` in `docs/website/physics/stellar-structure/energy-transport.md`.
- ASTRA documents and implements the transport row as

  ```math
  \Delta \log T + \nabla \, \Delta \log P = 0
  ```

  in `docs/website/methods/residual-assembly.md` and `src/numerics/residuals.jl`.

- The default hotspot payload at `artifacts/validation/2026-03-30-transport-hotspot-diagnostics/default-12.toml` shows:
  - `delta_log_temperature < 0`
  - `delta_log_pressure < 0`
  - `nabla_transport > 0`
  - `gradient_term < 0`
  - so the two transport terms currently reinforce rather than cancel.

### Candidate correction

If the documented `nabla` meaning is the intended one, the smallest canonical correction is:

- current:

  ```julia
  residual = delta_log_temperature + gradient_term
  gradient_term = nabla_transport * delta_log_pressure
  ```

- candidate:

  ```julia
  residual = delta_log_temperature - gradient_term
  gradient_term = nabla_transport * delta_log_pressure
  ```

That preserves the meaning of `gradient_term` as the physical `nabla * delta_log_pressure` contribution while correcting the residual sign.

### Scientific stop rules

- If the red tests show ASTRA already uses an opposite sign convention for `nabla` consistently, stop before changing code and correct the docs instead.
- If the sign correction changes more than the transport residual meaning or forces boundary ownership changes, stop and explain the mismatch before proceeding.
- Do not widen scope into adaptive regularization, convection, trust-region logic, or a new atmosphere-provider interface.

### Validation target for this slice

Success for this slice does **not** mean convergence. It means:

- the transport row and docs agree on one sign convention,
- the row no longer implies outward temperature increase when `delta_log_pressure < 0`,
- hotspot diagnostics still work under the corrected contract,
- and the refreshed artifact bundle tells us whether the surface-adjacent interior hotspot survives the correction.

### Task 1: Add Transport Sign-Contract Tests

**Files:**
- Create: `test/test_transport_sign_contract.jl`
- Modify: `test/runtests.jl`
- Modify: `test/test_outer_transport_boundary.jl`

**Step 1: Write the failing test**

Create `test/test_transport_sign_contract.jl`:

```julia
@testset "transport sign contract" begin
    problem = ASTRA.build_toy_problem(n_cells = 8)
    model = ASTRA.initialize_state(problem)
    n = problem.grid.n_cells

    interior = ASTRA.transport_row_terms(problem, model, 2)
    @test interior.delta_log_pressure < 0.0
    @test interior.nabla_transport > 0.0
    @test interior.delta_log_temperature ≈
          interior.nabla_transport * interior.delta_log_pressure
    @test interior.residual ≈
          interior.delta_log_temperature - interior.gradient_term

    outer = ASTRA.transport_row_terms(problem, model, n - 1)
    @test outer.delta_log_pressure < 0.0
    @test outer.nabla_transport > 0.0
    @test outer.residual ≈
          outer.delta_log_temperature - outer.gradient_term
end
```

**Step 2: Run test to verify it fails**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_transport_sign_contract.jl")'
```

Expected: FAIL because the current helper still reports `residual = delta_log_temperature + gradient_term`.

**Step 3: Write minimal implementation**

If the failure confirms the mismatch:

- update `transport_row_terms(...)` in `src/numerics/structure_equations.jl` so the residual is

  ```julia
  residual = delta_log_temperature - gradient_term
  ```

- keep

  ```julia
  gradient_term = nabla_transport * delta_log_pressure
  ```

  unchanged so the diagnostics still expose the physical signed term directly.

- update `test/test_outer_transport_boundary.jl` only if its expected row expression needs to be rewritten explicitly in the corrected sign form.

**Step 4: Run tests to verify they pass**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_transport_sign_contract.jl")'
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_transport_row_terms.jl"); include("test/test_outer_transport_boundary.jl")'
```

Expected: PASS.

**Step 5: Commit**

```bash
git add test/test_transport_sign_contract.jl test/runtests.jl test/test_outer_transport_boundary.jl src/numerics/structure_equations.jl
git commit -m "fix: correct transport sign contract"
```

### Task 2: Propagate The Corrected Sign Through Residual And Metric Tests

**Files:**
- Modify: `test/test_transport_row_weights.jl`
- Modify: `test/test_transport_hotspot_diagnostics.jl`
- Modify: `test/test_solver_progress_diagnostics.jl`
- Modify: `src/numerics/residuals.jl`
- Modify: `src/solvers/step_metrics.jl`

**Step 1: Write the failing test**

Add one explicit corrected-sign assertion to `test/test_transport_hotspot_diagnostics.jl`:

```julia
@test hotspot.raw_residual ≈
      hotspot.delta_log_temperature - hotspot.gradient_term
```

Add the same corrected-sign assertion in `test/test_solver_progress_diagnostics.jl` for accepted and rejected hotspot summaries.

**Step 2: Run test to verify it fails**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_transport_hotspot_diagnostics.jl"); include("test/test_solver_progress_diagnostics.jl")'
```

Expected: FAIL until the hotspot expectations and any dependent row semantics are aligned.

**Step 3: Write minimal implementation**

- keep `src/numerics/residuals.jl` routing through `transport_row_terms(...)`
- update `src/solvers/step_metrics.jl` only where tests or comments assume the old residual identity
- update `test/test_transport_row_weights.jl` only if the scale expectation should now refer to the corrected residual semantics rather than the old additive identity

Do not change weighting policy itself in this task.

**Step 4: Run tests to verify they pass**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_transport_row_weights.jl"); include("test/test_transport_hotspot_diagnostics.jl"); include("test/test_solver_progress_diagnostics.jl")'
```

Expected: PASS.

**Step 5: Commit**

```bash
git add test/test_transport_row_weights.jl test/test_transport_hotspot_diagnostics.jl test/test_solver_progress_diagnostics.jl src/numerics/residuals.jl src/solvers/step_metrics.jl
git commit -m "test: align transport diagnostics with corrected sign"
```

### Task 3: Update Physics And Methods Docs To Match The Corrected Contract

**Files:**
- Modify: `docs/website/physics/stellar-structure/energy-transport.md`
- Modify: `docs/website/methods/residual-assembly.md`
- Modify: `test/test_docs_structure.jl`

**Step 1: Write the failing docs test**

Extend `test/test_docs_structure.jl` to require the corrected transport row statement, for example:

- `"log T_{k+1} - log T_k - nabla_k"`
- or equivalent plain-text wording that says the transport residual subtracts the `nabla * delta_log_pressure` term.

**Step 2: Run test to verify it fails**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_docs_structure.jl")'
```

Expected: FAIL until the docs are updated.

**Step 3: Write minimal implementation**

Update:

- `docs/website/physics/stellar-structure/energy-transport.md`
- `docs/website/methods/residual-assembly.md`

so they state one corrected transport sign contract consistently, and explain briefly that the prior form was inconsistent with the documented `nabla` meaning.

**Step 4: Run test to verify it passes**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_docs_structure.jl")'
```

Expected: PASS.

**Step 5: Commit**

```bash
git add docs/website/physics/stellar-structure/energy-transport.md docs/website/methods/residual-assembly.md test/test_docs_structure.jl
git commit -m "docs: correct transport sign contract"
```

### Task 4: Refresh The Hotspot Bundle And Record The New Interpretation

**Files:**
- Modify: `docs/website/development/transport-outer-boundary-hardening-2026-03-30.md`
- Modify: `docs/website/development/progress-summary.md`
- Create: `artifacts/validation/2026-03-30-transport-sign-correction/`

**Step 1: Write the failing docs-structure test**

Add expectations in `test/test_docs_structure.jl` for the dated note and progress page to mention:

- `transport sign contract`
- and either `surface-adjacent interior` or the updated hotspot interpretation from the refreshed bundle.

**Step 2: Run test to verify it fails**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_docs_structure.jl")'
```

Expected: FAIL until the note is refreshed.

**Step 3: Write minimal implementation**

- rerun the validation suite into `artifacts/validation/2026-03-30-transport-sign-correction/`
- update the dated note and progress journal with:
  - the corrected contract,
  - the refreshed hotspot evidence,
  - what changed numerically,
  - and what the new bundle still does not prove

Be explicit about whether the default hotspot remains surface-adjacent interior after the correction.

**Step 4: Run verification**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_docs_structure.jl")'
cd /Users/anna/projects/julia-dev/astra/docs/website && myst build --site --html --strict
```

Expected: PASS.

**Step 5: Commit**

```bash
git add docs/website/development/transport-outer-boundary-hardening-2026-03-30.md docs/website/development/progress-summary.md test/test_docs_structure.jl
git add -A artifacts/validation/2026-03-30-transport-sign-correction
git commit -m "docs: record transport sign correction evidence"
```

### Task 5: Run Full Scientific Verification

**Files:**
- No code changes expected

**Step 1: Run required verification**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_center_asymptotic_scaling.jl")'
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_jacobian_fidelity_audit.jl")'
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_default_newton_progress.jl"); include("test/test_convergence_basin.jl")'
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_docs_structure.jl")'
cd /Users/anna/projects/julia-dev/astra/docs/website && myst build --site --html --strict
~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
```

**Step 2: Record expected outcome**

Expected:

- all tests pass,
- docs build passes,
- and the refreshed bundle is committed and interpretable.

**Step 3: Commit only if a final docs or artifact touch-up is needed**

If verification changes tracked outputs, commit them atomically with a docs-only message. Otherwise do not create an extra no-op commit.
