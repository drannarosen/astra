# Analytical Physics Completion Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Complete ASTRA's analytical classical-physics lane by adding residual-owned `eps_grav` and `eps_nu`, screening and optional triple-alpha in the analytical nuclear closure, and flag-gated degeneracy/Coulomb corrections in the analytical EOS, while keeping the current public ownership contract fixed.

**Architecture:** Keep `MicrophysicsBundle` and the public closure payloads narrow. Add a new internal energy-source helper lane that assembles `eps_nuc + eps_grav - eps_nu` for the luminosity row, with `eps_grav` owned by internal evolution/history bookkeeping rather than by a widened microphysics payload. Enrich nuclear and EOS analytically behind the existing closure interfaces, validate locally first, then rebaseline solver/Jacobian checks, and update the website physics/checklist surfaces in the same slice.

**Tech Stack:** Julia, existing `StellarModel`/`StructureProblem` ownership blocks in `src/foundation/types.jl`, ASTRA residual/Jacobian tests, MystMD docs, local Stellax reference code in `/Users/anna/projects/jaxstro-dev/stellax/src/stellax/physics/`, @test-driven-development, @verification-before-completion, @scientific-collaborator-mode

---

### Task 1: Lock the Energy-Source Completion Contract in Tests

**Files:**
- Create: `test/test_analytical_energy_sources.jl`
- Modify: `test/runtests.jl`
- Modify: `test/test_classical_residual_rows.jl`
- Modify: `test/test_block_jacobian.jl`
- Modify: `test/test_jacobian_fidelity_audit.jl`

**Step 1: Write the failing test**

Create `test/test_analytical_energy_sources.jl` with a focused contract for the new internal source helpers:

```julia
@testset "analytical energy sources" begin
    problem = ASTRA.build_toy_problem(n_cells = 6)
    model = initialize_state(problem)

    sources = ASTRA.energy_source_terms(problem, model, 2)

    @test sources.eps_nuc_erg_g_s > 0.0
    @test isfinite(sources.eps_grav_erg_g_s)
    @test isfinite(sources.eps_nu_erg_g_s)
    @test isfinite(sources.eps_total_erg_g_s)
    @test sources.eps_total_erg_g_s ≈
        sources.eps_nuc_erg_g_s + sources.eps_grav_erg_g_s - sources.eps_nu_erg_g_s
end
```

Extend `test/test_classical_residual_rows.jl` so the luminosity row is checked against the assembled total source instead of nuclear only:

```julia
sources = ASTRA.energy_source_terms(problem, model, 1)
dm_g = problem.grid.dm_cell_g[1]
@test block[3] ≈
    model.structure.luminosity_face_erg_s[2] -
    model.structure.luminosity_face_erg_s[1] -
    dm_g * sources.eps_total_erg_g_s
```

Tighten `test/test_jacobian_fidelity_audit.jl` so the luminosity family remains finite and below a declared tolerance after source decomposition, and add one explicit luminosity-family assertion in `test/test_block_jacobian.jl` comments if needed to make the intent clear.

**Step 2: Run test to verify it fails**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_analytical_energy_sources.jl")'
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_classical_residual_rows.jl")'
```

Expected: FAIL with missing `energy_source_terms` helper or luminosity-row assumptions still tied to `eps_nuc` only.

**Step 3: Write minimal implementation**

Wire the new test file into `test/runtests.jl` only:

```julia
include("test_analytical_energy_sources.jl")
```

Do not implement energy-source helpers yet. This task exists only to lock the red contract.

**Step 4: Run test to verify it fails**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/runtests.jl")'
```

Expected: FAIL in the new energy-source contract tests.

**Step 5: Commit**

```bash
git add test/runtests.jl test/test_analytical_energy_sources.jl test/test_classical_residual_rows.jl test/test_block_jacobian.jl test/test_jacobian_fidelity_audit.jl
git commit -m "test: lock analytical energy-source contract"
```

### Task 2: Add Evolution-Owned Gravothermal History and Internal Energy Helpers

**Files:**
- Create: `src/microphysics/energy_sources.jl`
- Modify: `src/ASTRA.jl`
- Modify: `src/foundation/types.jl`
- Modify: `src/foundation/state.jl`
- Test: `test/test_analytical_energy_sources.jl`

**Step 1: Write the failing test**

Strengthen `test/test_analytical_energy_sources.jl` with explicit history-driven `eps_grav` expectations:

```julia
history = ASTRA.with_previous_thermodynamic_state(
    model;
    previous_log_temperature_cell_k = model.structure.log_temperature_cell_k .- log(1.01),
    previous_log_density_cell_g_cm3 = model.structure.log_density_cell_g_cm3 .+ log(1.01),
    timestep_s = 1.0e11,
)
sources = ASTRA.energy_source_terms(problem, history, 2)

@test isfinite(sources.eps_grav_erg_g_s)
@test sources.eps_grav_owner == :evolution_history
```

Add one low-level helper test for the cp-form gravothermal rate:

```julia
eps_grav = ASTRA.Microphysics.eps_grav_from_cp(
    temperature_k = 1.5e7,
    specific_heat_erg_g_k = 1.0e8,
    adiabatic_gradient = 0.4,
    chi_temperature = 1.0,
    chi_density = 1.0,
    dlog_temperature_dt = 1.0e-14,
    dlog_density_dt = -2.0e-14,
)
@test isfinite(eps_grav)
```

**Step 2: Run test to verify it fails**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_analytical_energy_sources.jl")'
```

Expected: FAIL because the evolution-history helpers and gravothermal helper do not exist.

**Step 3: Write minimal implementation**

Create `src/microphysics/energy_sources.jl` with ASTRA-native internal helpers:

- `eps_grav_from_cp(...)`
- `analytical_neutrino_loss_rate(density_g_cm3, temperature_k, composition)`
- `energy_source_terms(problem, model, k)`

Use these references:

- `/Users/anna/projects/jaxstro-dev/stellax/src/stellax/physics/eps_grav.py`
- `/Users/anna/projects/jaxstro-dev/stellax/src/stellax/physics/energy_terms.py`
- `/Users/anna/projects/jaxstro-dev/stellax/src/stellax/physics/neutrino.py`

Implementation rules:

- Keep `eps_grav` internal and evolution-owned.
- Keep the current public microphysics payload unchanged.
- Introduce history bookkeeping through the existing `EvolutionState` block, not a new top-level ownership block.
- Keep the bookkeeping minimal and explicit, for example:

```julia
struct EvolutionState
    age_s::Float64
    timestep_s::Float64
    previous_timestep_s::Float64
    accepted_steps::Int
    rejected_steps::Int
    previous_log_temperature_cell_k::Union{Nothing,Vector{Float64}}
    previous_log_density_cell_g_cm3::Union{Nothing,Vector{Float64}}
end
```

Add `with_previous_thermodynamic_state(model; ...)` in `src/foundation/state.jl` so tests and future evolution code can build a history-backed model without widening the solve-owned structure state.

Keep the first neutrino slice analytical and minimal: implement one explicit thermal-neutrino helper that stays finite and monotone in the high-temperature regime rather than trying to port all of Itoh's process families at once.

**Step 4: Run test to verify it passes**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_analytical_energy_sources.jl")'
```

Expected: PASS with finite `eps_grav`, finite `eps_nu`, and an explicit `:evolution_history` owner tag.

**Step 5: Commit**

```bash
git add src/microphysics/energy_sources.jl src/ASTRA.jl src/foundation/types.jl src/foundation/state.jl test/test_analytical_energy_sources.jl
git commit -m "feat: add analytical energy-source helpers"
```

### Task 3: Wire `eps_grav` and `eps_nu` into the Luminosity Row and Jacobian

**Files:**
- Modify: `src/numerics/structure_equations.jl`
- Modify: `src/numerics/residuals.jl`
- Modify: `src/numerics/jacobians.jl`
- Test: `test/test_classical_residual_rows.jl`
- Test: `test/test_block_jacobian.jl`
- Test: `test/test_jacobian_fidelity_audit.jl`
- Test: `test/test_default_newton_progress.jl`

**Step 1: Write the failing test**

Extend `test/test_classical_residual_rows.jl` so the luminosity block uses `eps_total_erg_g_s`:

```julia
sources = ASTRA.energy_source_terms(problem, model, 1)
@test ASTRA.interior_structure_block(problem, model, 1)[3] ≈
    model.structure.luminosity_face_erg_s[2] -
    model.structure.luminosity_face_erg_s[1] -
    problem.grid.dm_cell_g[1] * sources.eps_total_erg_g_s
```

Add a luminosity-family fidelity assertion in `test/test_jacobian_fidelity_audit.jl` that remains quantitative after the new source decomposition:

```julia
@test audit.luminosity.max_rel_error <= 1.0e-3
```

**Step 2: Run test to verify it fails**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_classical_residual_rows.jl")'
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_jacobian_fidelity_audit.jl")'
```

Expected: FAIL because the residual and Jacobian still only own `eps_nuc`.

**Step 3: Write minimal implementation**

Update the residual and Jacobian to consume the new assembled source:

- In `src/numerics/structure_equations.jl`, add `cell_energy_source_state(problem, model, k) = energy_source_terms(problem, model, k)`.
- In `src/numerics/residuals.jl`, replace `dm_g * energy_rate_k_erg_g_s` with `dm_g * eps_total_erg_g_s`.
- In `src/numerics/jacobians.jl`, keep the packed-variable chain-rule structure explicit and use centered local source derivatives for the new total source if a clean analytic split is not yet worth hand-coding.

Do not widen the packed solve vector. Keep the row basis in `(\log r, L, \log T, \log \rho)`.

**Step 4: Run test to verify it passes**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_classical_residual_rows.jl")'
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_block_jacobian.jl"); include("test/test_jacobian_fidelity_audit.jl"); include("test/test_default_newton_progress.jl")'
```

Expected: PASS, with the luminosity-row audits still finite and within the declared tolerances.

**Step 5: Commit**

```bash
git add src/numerics/structure_equations.jl src/numerics/residuals.jl src/numerics/jacobians.jl test/test_classical_residual_rows.jl test/test_block_jacobian.jl test/test_jacobian_fidelity_audit.jl test/test_default_newton_progress.jl
git commit -m "feat: wire analytical energy sources into luminosity row"
```

### Task 4: Enrich Analytical Nuclear Physics with Screening and Optional Triple-Alpha

**Files:**
- Modify: `src/microphysics/nuclear.jl`
- Test: `test/test_analytical_nuclear.jl`
- Test: `test/test_local_derivative_validation.jl`
- Test: `test/test_microphysics_interfaces.jl`

**Step 1: Write the failing test**

Strengthen `test/test_analytical_nuclear.jl` with screening and gated triple-alpha checks:

```julia
screened = ASTRA.Microphysics.AnalyticalNuclear(include_screening = true)
unscreened = ASTRA.Microphysics.AnalyticalNuclear(include_screening = false)
he_burning = ASTRA.Microphysics.AnalyticalNuclear(include_3alpha = true)

@test screened(150.0, 1.5e7, composition).energy_rate_erg_g_s >=
    unscreened(150.0, 1.5e7, composition).energy_rate_erg_g_s
@test he_burning(1.0e4, 1.5e8, Composition(0.0, 0.98, 0.02)).energy_rate_erg_g_s > 0.0
```

Add one derivative sanity check for the screened path at a solar-center-like state.

**Step 2: Run test to verify it fails**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_analytical_nuclear.jl")'
```

Expected: FAIL because screening and triple-alpha are still inactive or incomplete in the current implementation.

**Step 3: Write minimal implementation**

In `src/microphysics/nuclear.jl`:

- port the weak Salpeter screening factor from `/Users/anna/projects/jaxstro-dev/stellax/src/stellax/physics/nuclear/screening.py`,
- apply it to PP and CNO when `include_screening = true`,
- finish the optional triple-alpha path so it is compiled, gated, and differentiated by the existing local derivative helpers,
- keep the public payload as:

```julia
(energy_rate_erg_g_s = clip_positive(ε_total), source = :analytical_nuclear)
```

Do not add abundance time derivatives to the public closure payload.

**Step 4: Run test to verify it passes**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_analytical_nuclear.jl"); include("test/test_microphysics_interfaces.jl"); include("test/test_local_derivative_validation.jl")'
```

Expected: PASS, with the default path still finite and the gated paths behaving as declared.

**Step 5: Commit**

```bash
git add src/microphysics/nuclear.jl test/test_analytical_nuclear.jl test/test_microphysics_interfaces.jl test/test_local_derivative_validation.jl
git commit -m "feat: enrich analytical nuclear physics"
```

### Task 5: Enrich the Analytical EOS with Flag-Gated Degeneracy and Coulomb Terms

**Files:**
- Modify: `src/microphysics/eos.jl`
- Test: `test/test_analytical_eos.jl`
- Test: `test/test_local_derivative_validation.jl`
- Test: `test/test_structure_equations.jl`

**Step 1: Write the failing test**

Extend `test/test_analytical_eos.jl` with gated-regime checks:

```julia
degenerate = ASTRA.Microphysics.AnalyticalGasRadiationEOS(include_degeneracy = true)
coulomb = ASTRA.Microphysics.AnalyticalGasRadiationEOS(include_coulomb = true)
composition = Composition(0.70, 0.28, 0.02)

deg_state = degenerate(1.0e6, 1.0e7, composition)
base_state = ASTRA.Microphysics.AnalyticalGasRadiationEOS()(1.0e6, 1.0e7, composition)
@test deg_state.pressure_dyn_cm2 >= base_state.pressure_dyn_cm2

coulomb_state = coulomb(1.0e2, 1.0e7, composition)
@test isfinite(coulomb_state.pressure_dyn_cm2)
@test isfinite(ASTRA.Microphysics.pressure_temperature_derivative(coulomb, 1.0e2, 1.0e7, composition))
```

Keep the default no-flags path fully green and unchanged in semantics.

**Step 2: Run test to verify it fails**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_analytical_eos.jl")'
```

Expected: FAIL because the flags exist but do not yet alter the thermodynamics.

**Step 3: Write minimal implementation**

In `src/microphysics/eos.jl`, port the analytical enrichments from:

- `/Users/anna/projects/jaxstro-dev/stellax/src/stellax/physics/eos/ideal_gas.py`

Specifically:

- Paczynski-style electron degeneracy interpolation for the electron contribution,
- Debye-Huckel Coulomb correction as a negative pressure correction,
- `chi_rho` and `chi_T` terms needed by `eps_grav_from_cp`,
- keep both enrichments flag-gated first,
- preserve the current public payload fields ASTRA already consumes.

Do not port the JAX inversion interface or entropy-authoritative ownership in this slice.

**Step 4: Run test to verify it passes**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_analytical_eos.jl"); include("test/test_structure_equations.jl"); include("test/test_local_derivative_validation.jl")'
```

Expected: PASS for the default path and finite derivatives for the gated enrichments.

**Step 5: Commit**

```bash
git add src/microphysics/eos.jl test/test_analytical_eos.jl test/test_structure_equations.jl test/test_local_derivative_validation.jl
git commit -m "feat: enrich analytical eos physics"
```

### Task 6: Update Physics Pages, Checklists, and Full Verification

**Files:**
- Modify: `docs/website/physics/eos.md`
- Modify: `docs/website/physics/eos/analytical-eos.md`
- Modify: `docs/website/physics/nuclear.md`
- Modify: `docs/website/physics/nuclear/analytical-burning.md`
- Modify: `docs/website/physics/stellar-structure/energy-generation.md`
- Modify: `docs/website/physics/stellar-structure/coupled-problem.md`
- Modify: `docs/website/numerics/residuals.md`
- Modify: `docs/website/methods/jacobian-construction.md`
- Modify: `docs/website/development/checklists/solar-first-lane.md`
- Modify: `test/test_docs_structure.jl`

**Step 1: Write the failing test**

Update `test/test_docs_structure.jl` so the relevant pages must now mention:

- `eps_grav`,
- `eps_nu`,
- evolution-owned gravothermal history,
- screening and optional triple-alpha,
- degeneracy and Coulomb flags,
- what is active by default vs what remains flag-gated.

For example:

```julia
"energy-generation.md" => [
    "eps_grav",
    "eps_nu",
    "evolution history",
    "What is deferred",
],
```

**Step 2: Run test to verify it fails**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_docs_structure.jl")'
```

Expected: FAIL because the docs and checklist pages still describe the earlier analytical slice.

**Step 3: Write minimal implementation**

Update the website docs and checklist pages so they describe the new analytical lane honestly:

- `eps_grav` is now an internal evolution-owned analytical source term,
- `eps_nu` is now part of the residual-owned source decomposition,
- screening and triple-alpha exist and are flag-gated unless explicitly default-on by validation,
- degeneracy and Coulomb terms exist and remain flag-gated until further validation if they are not promoted in this slice,
- composition evolution is still outside the public closure payload.

Keep the checklists explicit about what is still deferred after this slice.

**Step 4: Run test to verify it passes**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_docs_structure.jl")'
cd /Users/anna/projects/julia-dev/astra/docs/website && myst build --site --html --strict
~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
```

Expected: PASS for docs structure, strict MyST build, and the full ASTRA test suite.

**Step 5: Commit**

```bash
git add docs/website/physics/eos.md docs/website/physics/eos/analytical-eos.md docs/website/physics/nuclear.md docs/website/physics/nuclear/analytical-burning.md docs/website/physics/stellar-structure/energy-generation.md docs/website/physics/stellar-structure/coupled-problem.md docs/website/numerics/residuals.md docs/website/methods/jacobian-construction.md docs/website/development/checklists/solar-first-lane.md test/test_docs_structure.jl
git commit -m "docs: update handbook for analytical physics completion"
```
