# Classical Baseline Next Steps Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Improve ASTRA's classical baseline by making the placeholder-physics solve more trustworthy, validating local derivative readiness, replacing the global finite-difference Jacobian with a block-aware path, and stabilizing the future differentiable-solver boundary.

**Architecture:** This plan stays on ASTRA's current narrow classical lane. It does not add real EOS tables, real opacity tables, real MLT, `eps_grav`, PMS evolution algorithms, or Entropy-DAE expansion. The work is staged so that convergence quality and derivative honesty improve before ASTRA adopts broader solver or sensitivity infrastructure.

**Tech Stack:** Julia 1.12, stdlib `Test`, current ASTRA package scaffold, placeholder microphysics, MystMD docs, @test-driven-development, @verification-before-completion, @scientific-collaborator-mode

---

### Task 1: Improve The Classical Baseline Convergence Basin

**Files:**
- Create: `test/test_convergence_basin.jl`
- Modify: `test/runtests.jl`
- Modify: `src/state.jl`
- Modify: `src/config.jl`
- Modify: `src/solvers/nonlinear_solvers.jl`
- Modify: `src/diagnostics.jl`
- Modify: `examples/basic_structure_demo.jl`
- Modify: `scripts/run_examples.jl`
- Modify: `docs/website/development/issues.md`
- Modify: `docs/website/development/progress-summary.md`

**Step 1: Write the failing test**

Create `test/test_convergence_basin.jl`:

```julia
@testset "classical convergence basin" begin
    problem = ASTRA.build_toy_problem(n_cells = 12)
    result = solve_structure(problem)

    @test result.state isa ASTRA.StellarModel
    @test result.diagnostics.residual_norm < 1.0e31
    @test any(note -> occursin("initial guess", lowercase(note)), result.diagnostics.notes)
end
```

The point of this first test is not to require full convergence to zero residual yet. It is to force ASTRA to improve the current default solve enough that the residual norm is materially smaller than the current `~1e33` example regime and that diagnostics explicitly explain the initialization strategy.

**Step 2: Run test to verify it fails**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_convergence_basin.jl")'
```

Expected: FAIL because the current initialization and solve path do not yet reduce the residual enough and the diagnostics do not yet describe a convergence-basin-aware initial guess.

**Step 3: Write minimal implementation**

Make the smallest changes that improve the baseline honestly:

- add one or two optional fields to `SolverConfig` only if needed for bounded damping or line-search floor,
- improve `_analytic_profile_state` in `src/state.jl` so the initial radius, luminosity, temperature, and density profiles better satisfy the current center/surface closures,
- add a bounded residual-reduction safeguard to `solve_nonlinear_system` if the current full-step update makes the residual worse,
- add explicit diagnostics notes describing the initialization and any damping or rejection logic used,
- update `examples/basic_structure_demo.jl` to print the final iteration count in addition to convergence and residual norm.

Keep the implementation narrow. Do not introduce generic optimization infrastructure, external solvers, or new physics here.

**Step 4: Run test to verify it passes**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_convergence_basin.jl")'
```

Expected: PASS with a materially improved residual norm and diagnostics notes mentioning the initial guess or damping strategy.

**Step 5: Run broader verification**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_solve_contract.jl"); include("test/test_convergence_basin.jl")'
~/.juliaup/bin/julia --project=. scripts/run_examples.jl
```

Expected:

- both tests PASS,
- `basic_structure_demo` shows a lower residual norm than the current baseline,
- if it is still not converged, the example and diagnostics remain explicit about that.

**Step 6: Commit**

```bash
git add test/test_convergence_basin.jl test/runtests.jl src/state.jl src/config.jl src/solvers/nonlinear_solvers.jl src/diagnostics.jl examples/basic_structure_demo.jl scripts/run_examples.jl docs/website/development/issues.md docs/website/development/progress-summary.md
git commit -m "Improve classical baseline convergence basin"
```

### Task 2: Add Local Derivative Validation For Classical Helper Kernels

**Files:**
- Create: `test/test_local_derivative_validation.jl`
- Modify: `test/runtests.jl`
- Modify: `src/structure_equations.jl`
- Modify: `src/microphysics/eos.jl`
- Modify: `src/microphysics/opacity.jl`
- Modify: `src/microphysics/nuclear.jl`
- Modify: `docs/website/architecture/differentiability-strategy.md`
- Modify: `docs/website/planning/differentiable-astra-roadmap.md`

**Step 1: Write the failing test**

Create `test/test_local_derivative_validation.jl`:

```julia
@testset "local derivative validation" begin
    problem = ASTRA.build_toy_problem(n_cells = 6)
    model = initialize_state(problem)
    k = 2

    fd = ASTRA.finite_difference_temperature_gradient_sensitivity(problem, model, k)
    analytic = ASTRA.helper_temperature_gradient_sensitivity(problem, model, k)

    @test isfinite(fd)
    @test isfinite(analytic)
    @test isapprox(analytic, fd; rtol = 1.0e-4, atol = 1.0e-8)
end
```

The exact helper names can differ, but the test must compare one explicit local sensitivity against a finite-difference reference. Start with the radiative-temperature-gradient helper because it already couples EOS, opacity, luminosity, pressure, and temperature in one place.

**Step 2: Run test to verify it fails**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_local_derivative_validation.jl")'
```

Expected: FAIL because ASTRA does not yet expose explicit derivative-validation helpers for these local kernels.

**Step 3: Write minimal implementation**

Implement only the smallest derivative-validation layer needed for the test:

- add one finite-difference helper in `src/structure_equations.jl` for the selected local quantity,
- add one explicit comparison helper or directional derivative function for the same quantity,
- keep the code local and kernel-level, not global-solver-level,
- if you need to expose more than one local derivative, do them one at a time with matching tests.

Do not add full package dependencies for AD yet in this task. The purpose here is to define the validation shape and prove ASTRA knows where local derivatives should live.

**Step 4: Run test to verify it passes**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_local_derivative_validation.jl")'
```

Expected: PASS with a documented finite-difference agreement threshold.

**Step 5: Run broader verification**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_structure_equations.jl"); include("test/test_microphysics_interfaces.jl"); include("test/test_local_derivative_validation.jl")'
```

Expected: PASS across helper, microphysics-interface, and local-derivative tests.

**Step 6: Commit**

```bash
git add test/test_local_derivative_validation.jl test/runtests.jl src/structure_equations.jl src/microphysics/eos.jl src/microphysics/opacity.jl src/microphysics/nuclear.jl docs/website/architecture/differentiability-strategy.md docs/website/planning/differentiable-astra-roadmap.md
git commit -m "Add local derivative validation for classical helpers"
```

### Task 3: Replace The Global Finite-Difference Jacobian With A Block-Aware Path

**Files:**
- Create: `test/test_block_jacobian.jl`
- Modify: `test/runtests.jl`
- Modify: `src/jacobians.jl`
- Modify: `src/residuals.jl`
- Modify: `src/structure_equations.jl`
- Modify: `src/solvers/linear_solvers.jl`
- Modify: `docs/website/numerics/jacobians.md`
- Modify: `docs/website/numerics/linear-solvers.md`

**Step 1: Write the failing test**

Create `test/test_block_jacobian.jl`:

```julia
@testset "block jacobian" begin
    problem = ASTRA.build_toy_problem(n_cells = 6)
    model = initialize_state(problem)

    jacobian = ASTRA.structure_jacobian(problem, model)
    fd_jacobian = ASTRA.finite_difference_jacobian(problem, model)

    @test size(jacobian) == size(fd_jacobian)
    @test all(isfinite, jacobian)
    @test isapprox(jacobian, fd_jacobian; rtol = 1.0e-3, atol = 1.0e-6)
end
```

This test defines the acceptance criterion for the new path: same shape, finite entries, and reasonable agreement with the current finite-difference reference.

**Step 2: Run test to verify it fails**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_block_jacobian.jl")'
```

Expected: FAIL because `structure_jacobian` does not exist yet or because it still aliases the old global finite-difference path.

**Step 3: Write minimal implementation**

Implement the smallest block-aware Jacobian path that respects current ownership:

- add `structure_jacobian(problem, model)` in `src/jacobians.jl`,
- assemble row blocks in the same physical order as the residual,
- start with local partials for center rows, interior rows, and surface rows,
- if a full analytic block is too large for one slice, use hybrid assembly: explicit local derivatives where available plus finite-difference fallback for untouched terms,
- update `src/solvers/linear_solvers.jl` only if the new Jacobian representation needs a small adaptation before `\` can be applied.

Do not introduce `LinearSolve` yet. Keep the representation and solve path local to ASTRA in this task.

**Step 4: Run test to verify it passes**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_block_jacobian.jl")'
```

Expected: PASS with reasonable agreement against the finite-difference reference.

**Step 5: Run broader verification**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_jacobian_scaffold.jl"); include("test/test_block_jacobian.jl"); include("test/test_solve_contract.jl")'
```

Expected: PASS, and the solve contract remains honest on the new Jacobian path.

**Step 6: Commit**

```bash
git add test/test_block_jacobian.jl test/runtests.jl src/jacobians.jl src/residuals.jl src/structure_equations.jl src/solvers/linear_solvers.jl docs/website/numerics/jacobians.md docs/website/numerics/linear-solvers.md
git commit -m "Add block-aware Jacobian path for classical solve"
```

### Task 4: Stabilize The Future Solver-Boundary API For Sensitivities

**Files:**
- Create: `test/test_solver_boundary_api.jl`
- Modify: `test/runtests.jl`
- Modify: `src/ASTRA.jl`
- Modify: `src/solvers/nonlinear_solvers.jl`
- Modify: `src/diagnostics.jl`
- Modify: `docs/website/architecture/differentiability-strategy.md`
- Modify: `docs/website/planning/differentiable-astra-roadmap.md`
- Modify: `docs/website/development/backlog.md`

**Step 1: Write the failing test**

Create `test/test_solver_boundary_api.jl`:

```julia
@testset "solver boundary api" begin
    problem = ASTRA.build_toy_problem(n_cells = 8)
    guess = initialize_state(problem)

    result = ASTRA.solve_structure(problem; state = guess)

    @test result isa ASTRA.SolveResult
    @test result.state isa ASTRA.StellarModel
    @test result.state.composition === guess.composition
    @test result.state.evolution !== nothing
    @test any(note -> occursin("solve boundary", lowercase(note)), result.diagnostics.notes)
end
```

This task is not about implementing sensitivities yet. It is about stabilizing the API shape and diagnostics language that later sensitivity work will target.

**Step 2: Run test to verify it fails**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_solver_boundary_api.jl")'
```

Expected: FAIL because the current diagnostics and public API do not yet explicitly describe the solve boundary in a way that future derivative rules can target.

**Step 3: Write minimal implementation**

Implement the smallest API and diagnostics refinements that make the future derivative boundary explicit:

- keep `solve_structure(problem; state = guess)` as the canonical public entry point,
- add one helper note or metadata line in diagnostics explicitly identifying the converged-structure solve as a boundary for later sensitivities,
- keep ownership unchanged: only the structure block is solve-owned,
- add no AD package dependency and no custom `rrule` yet.

This task is about interface stabilization, not sensitivity implementation.

**Step 4: Run test to verify it passes**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_solver_boundary_api.jl")'
```

Expected: PASS with the public API and diagnostics spelling out the boundary clearly.

**Step 5: Run broader verification**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_solve_contract.jl"); include("test/test_solver_boundary_api.jl")'
~/.juliaup/bin/julia --project=. scripts/run_examples.jl
```

Expected: PASS, with examples still running and diagnostics still honest about actual convergence state.

**Step 6: Commit**

```bash
git add test/test_solver_boundary_api.jl test/runtests.jl src/ASTRA.jl src/solvers/nonlinear_solvers.jl src/diagnostics.jl docs/website/architecture/differentiability-strategy.md docs/website/planning/differentiable-astra-roadmap.md docs/website/development/backlog.md
git commit -m "Stabilize classical solve boundary for future sensitivities"
```

### Task 5: Full Verification And Close-Out

**Files:**
- Modify: `docs/website/development/progress-summary.md`
- Modify: `docs/website/development/issues.md`

**Step 1: Run full verification before editing close-out notes**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
~/.juliaup/bin/julia --project=. scripts/run_examples.jl
cd docs/website && myst build --site --html --strict
```

Expected:

- all tests PASS,
- examples run and report their actual convergence status,
- docs build cleanly.

If the sandboxed Myst build hits the known port-binding restriction after a clean page/link build, rerun it outside the sandbox before recording the result.

**Step 2: Write minimal close-out updates**

Update the development pages to record:

- what the four steps proved,
- what still does not converge or validate cleanly,
- and what the next remaining blocker is after this plan lands.

Be explicit about what remains provisional.

**Step 3: Run the same verification again**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
~/.juliaup/bin/julia --project=. scripts/run_examples.jl
cd docs/website && myst build --site --html --strict
```

Expected: PASS with no regressions after the close-out notes.

**Step 4: Commit**

```bash
git add docs/website/development/progress-summary.md docs/website/development/issues.md
git commit -m "Record classical baseline readiness progress"
```
