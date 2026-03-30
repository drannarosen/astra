# Physics + Methods Docs Expansion Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Expand ASTRA's website into a detailed `Physics` + `Methods` reference, migrate relevant pedagogical material from Stellax, and ground all MESA-comparison content in the local MESA source tree.

**Architecture:** Keep `Physics` as the continuous-equations and closure layer, add a new `Methods` subtree for ASTRA's computational realization, and add a dedicated `methods/mesa-reference/` comparison subtree. Reuse Stellax pedagogy aggressively where it matches ASTRA's current scientific scope, but rewrite or exclude any text that would oversell ASTRA's current implementation.

**Tech Stack:** MystMD site, Markdown, existing ASTRA docs contract tests, local Stellax docs at `/Users/anna/projects/jaxstro-dev/stellax/docs/website/theory/` and `/methods/`, local MESA source mirror at `/Users/anna/projects/jaxstro-dev/legacy/stellax-legacy/reference/mesa/`, @test-driven-development, @verification-before-completion, @scientific-collaborator-mode

---

### Task 1: Add the New Docs Skeleton and Navigation

**Files:**
- Modify: `docs/website/myst.yml`
- Modify: `test/test_docs_structure.jl`
- Create: `docs/website/physics/index.md`
- Create: `docs/website/physics/stellar-structure/mass-conservation.md`
- Create: `docs/website/physics/stellar-structure/hydrostatic-equilibrium.md`
- Create: `docs/website/physics/stellar-structure/energy-generation.md`
- Create: `docs/website/physics/stellar-structure/energy-transport.md`
- Create: `docs/website/physics/stellar-structure/coupled-problem.md`
- Create: `docs/website/physics/eos/ideal-gas-plus-radiation.md`
- Create: `docs/website/physics/opacity/kramers-opacity.md`
- Create: `docs/website/physics/nuclear/pp-toy-heating.md`
- Create: `docs/website/physics/convection/radiative-gradient-and-criterion-hook.md`
- Create: `docs/website/methods/index.md`
- Create: `docs/website/methods/from-equations-to-residual.md`
- Create: `docs/website/methods/staggered-mesh-and-state-layout.md`
- Create: `docs/website/methods/residual-assembly.md`
- Create: `docs/website/methods/jacobian-construction.md`
- Create: `docs/website/methods/linear-solves-and-scaling.md`
- Create: `docs/website/methods/nonlinear-newton-and-backtracking.md`
- Create: `docs/website/methods/initial-model-and-seeding.md`
- Create: `docs/website/methods/boundary-condition-realization.md`
- Create: `docs/website/methods/verification-and-jacobian-audits.md`
- Create: `docs/website/methods/mesa-reference/index.md`
- Create: `docs/website/methods/mesa-reference/solver-scaling.md`
- Create: `docs/website/methods/mesa-reference/boundary-conditions.md`
- Create: `docs/website/methods/mesa-reference/mesh-and-variables.md`

**Step 1: Write the failing test**

Extend `test/test_docs_structure.jl` to require the new pages and the new `Methods` section in `myst.yml`.

Add assertions that:

- `docs/website/physics/index.md` exists,
- the new `physics/stellar-structure/*.md` pages exist,
- the new `methods/*.md` pages exist,
- the new `methods/mesa-reference/*.md` pages exist,
- `myst.yml` contains a `Methods` section instead of the old `Numerics` section title,
- and the old top-level physics hub pages are still present.

**Step 2: Run test to verify it fails**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_docs_structure.jl")'
```

Expected: FAIL because the new files and navigation do not exist yet.

**Step 3: Write minimal implementation**

- Update `docs/website/myst.yml`:
  - keep the `Physics` section,
  - add `physics/index.md`,
  - nest the deeper physics pages under `Physics`,
  - replace the `Numerics` section title with `Methods`,
  - add the new methods pages and the `mesa-reference` subtree.
- Create all new files with minimal but honest placeholder headings and one-paragraph purpose statements.
- Do not yet expand the old hub pages fully in this task; the goal is to land the navigation skeleton and make the site buildable.

**Step 4: Run test to verify it passes**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_docs_structure.jl")'
```

Expected: PASS for the file-existence and navigation-structure assertions.

**Step 5: Commit**

```bash
git add docs/website/myst.yml test/test_docs_structure.jl docs/website/physics docs/website/methods
git commit -m "Add physics and methods docs skeleton"
```

### Task 2: Expand the Physics Landing Pages and Hubs

**Files:**
- Modify: `docs/website/physics/stellar-structure.md`
- Modify: `docs/website/physics/eos.md`
- Modify: `docs/website/physics/opacity.md`
- Modify: `docs/website/physics/nuclear.md`
- Modify: `docs/website/physics/convection.md`
- Modify: `docs/website/physics/boundary-conditions.md`
- Modify: `docs/website/physics/index.md`
- Test: `test/test_docs_structure.jl`

**Step 1: Write the failing test**

Expand `test/test_docs_structure.jl` contract checks so the hub pages must now contain:

- `docs/website/physics/index.md`
  - `"Structure equations"`
  - `"Constitutive physics"`
  - `"Boundary conditions"`
- `docs/website/physics/stellar-structure.md`
  - `"Current ASTRA implementation"`
  - `"Numerical realization in ASTRA"`
- `docs/website/physics/eos.md`
  - `"Current ASTRA implementation"`
  - `"ideal gas plus radiation"`
- `docs/website/physics/opacity.md`
  - `"Current ASTRA implementation"`
  - `"Kramers"`
- `docs/website/physics/nuclear.md`
  - `"Current ASTRA implementation"`
  - `"pp-toy"`
- `docs/website/physics/convection.md`
  - `"Current ASTRA implementation"`
  - `"criterion hook"`
- `docs/website/physics/boundary-conditions.md`
  - `"Current ASTRA implementation"`
  - `"Numerical realization in ASTRA"`

**Step 2: Run test to verify it fails**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_docs_structure.jl")'
```

Expected: FAIL because the new sections and exact phrases are not yet present.

**Step 3: Write minimal implementation**

Using Stellax theory pages only as source material for pedagogy and equation framing:

- expand `physics/index.md` into a real landing page modeled on Stellax’s `theory/index.md`,
- rewrite each existing physics hub page into a true hub with:
  - a plain-language intro,
  - the continuous equation role,
  - a `Current ASTRA implementation` section,
  - a `Numerical realization in ASTRA` section,
  - a `What is deferred` section,
  - links to the corresponding deeper physics pages and methods pages.

Do not import production-physics claims from Stellax.

**Step 4: Run test to verify it passes**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_docs_structure.jl")'
```

Expected: PASS with the new hub-page contracts.

**Step 5: Commit**

```bash
git add docs/website/physics test/test_docs_structure.jl
git commit -m "Expand physics hub pages"
```

### Task 3: Write the Structure-Equation Physics Pages

**Files:**
- Modify: `docs/website/physics/stellar-structure/mass-conservation.md`
- Modify: `docs/website/physics/stellar-structure/hydrostatic-equilibrium.md`
- Modify: `docs/website/physics/stellar-structure/energy-generation.md`
- Modify: `docs/website/physics/stellar-structure/energy-transport.md`
- Modify: `docs/website/physics/stellar-structure/coupled-problem.md`
- Modify: `test/test_docs_structure.jl`

**Step 1: Write the failing test**

Add contract assertions requiring:

- `mass-conservation.md`
  - `dr/dm`
  - `"shell volume"`
  - `"Numerical realization in ASTRA"`
- `hydrostatic-equilibrium.md`
  - `dP/dm`
  - `"pressure support"`
  - `"Current ASTRA implementation"`
- `energy-generation.md`
  - `dL/dm`
  - `"eps_nuc"`
  - `"What is deferred"`
- `energy-transport.md`
  - `dT/dm`
  - `"radiative gradient"`
  - `"log(T"`
- `coupled-problem.md`
  - `"boundary-value problem"`
  - `"Jacobian"`
  - `"placeholder closures"`

**Step 2: Run test to verify it fails**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_docs_structure.jl")'
```

Expected: FAIL because the equation pages are still skeletal.

**Step 3: Write minimal implementation**

Use the following Stellax sources as pedagogical starting points:

- `theory/structure-equations/index.md`
- `theory/structure-equations/mass-conservation.md`
- `theory/structure-equations/hydrostatic-equilibrium.md`
- `theory/structure-equations/energy-generation.md`
- `theory/structure-equations/energy-transport.md`
- `theory/structure-equations/the-coupled-problem.md`

For each ASTRA page:

- give the continuous equation in mass coordinate,
- define all symbols,
- explain the physical job of the equation,
- state the exact simplified ASTRA discrete form now used,
- link to the matching methods page,
- include an explicit deferred-scope note where needed.

**Step 4: Run test to verify it passes**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_docs_structure.jl")'
```

Expected: PASS with the structure-equation contracts satisfied.

**Step 5: Commit**

```bash
git add docs/website/physics/stellar-structure test/test_docs_structure.jl
git commit -m "Add detailed structure-equation physics docs"
```

### Task 4: Write the Closure-Specific Physics Pages

**Files:**
- Modify: `docs/website/physics/eos/ideal-gas-plus-radiation.md`
- Modify: `docs/website/physics/opacity/kramers-opacity.md`
- Modify: `docs/website/physics/nuclear/pp-toy-heating.md`
- Modify: `docs/website/physics/convection/radiative-gradient-and-criterion-hook.md`
- Modify: `test/test_docs_structure.jl`

**Step 1: Write the failing test**

Add contract assertions requiring:

- `ideal-gas-plus-radiation.md`
  - `"pressure decomposition"`
  - `"dP/dT"`
  - `"dP/drho"`
- `kramers-opacity.md`
  - `"Rosseland"`
  - `"dκ/dT"`
  - `"dκ/drho"`
- `pp-toy-heating.md`
  - `"energy rate"`
  - `"dε/dT"`
  - `"dε/drho"`
- `radiative-gradient-and-criterion-hook.md`
  - `"nabla_rad"`
  - `"nabla_ad"`
  - `"residual still uses radiative transport"`

**Step 2: Run test to verify it fails**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_docs_structure.jl")'
```

Expected: FAIL because the closure pages do not yet contain the exact equations and derivative story.

**Step 3: Write minimal implementation**

Source material:

- Stellax theory pages for pedagogy only,
- ASTRA code in `src/microphysics/*.jl` and `src/structure_equations.jl` for exact current equations.

Each page must include:

- the exact current ASTRA formula,
- the exact derivative payloads ASTRA now uses,
- how that closure enters the residual or Jacobian,
- and a blunt deferred-scope note.

**Step 4: Run test to verify it passes**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_docs_structure.jl")'
```

Expected: PASS for all closure-page contracts.

**Step 5: Commit**

```bash
git add docs/website/physics/eos docs/website/physics/opacity docs/website/physics/nuclear docs/website/physics/convection test/test_docs_structure.jl
git commit -m "Document current ASTRA closure equations"
```

### Task 5: Build the Methods Pages from Current ASTRA Code

**Files:**
- Modify: `docs/website/methods/index.md`
- Modify: `docs/website/methods/from-equations-to-residual.md`
- Modify: `docs/website/methods/staggered-mesh-and-state-layout.md`
- Modify: `docs/website/methods/residual-assembly.md`
- Modify: `docs/website/methods/jacobian-construction.md`
- Modify: `docs/website/methods/linear-solves-and-scaling.md`
- Modify: `docs/website/methods/nonlinear-newton-and-backtracking.md`
- Modify: `docs/website/methods/initial-model-and-seeding.md`
- Modify: `docs/website/methods/boundary-condition-realization.md`
- Modify: `docs/website/methods/verification-and-jacobian-audits.md`
- Modify: `test/test_docs_structure.jl`

**Step 1: Write the failing test**

Add contract assertions requiring:

- `methods/index.md`
  - `"solve pipeline"`
  - `"Physics"`
  - `"Methods"`
- `from-equations-to-residual.md`
  - `"unknown vector"`
  - `"residual vector"`
  - `"log(radius"`
- `staggered-mesh-and-state-layout.md`
  - `"face-centered"`
  - `"cell-centered"`
  - `"packed state"`
- `residual-assembly.md`
  - `"center rows"`
  - `"interior blocks"`
  - `"surface rows"`
- `jacobian-construction.md`
  - `"analytic rows"`
  - `"central differences"`
  - `"jacobian_fidelity_audit"`
- `linear-solves-and-scaling.md`
  - `"erg/s"`
  - `"column scaling"`
  - `"regularized normal equations"`
- `nonlinear-newton-and-backtracking.md`
  - `"damping"`
  - `"accepted steps"`
  - `"rejected trials"`
- `initial-model-and-seeding.md`
  - `"geometry-consistent"`
  - `"source-matched"`
  - `"surface-anchored"`
- `boundary-condition-realization.md`
  - `"center asymptotic"`
  - `"surface closure"`
  - `"subtractive-cancellation"`
- `verification-and-jacobian-audits.md`
  - `"local derivative validation"`
  - `"block jacobian"`
  - `"default newton progress"`

**Step 2: Run test to verify it fails**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_docs_structure.jl")'
```

Expected: FAIL because the methods pages are still placeholders.

**Step 3: Write minimal implementation**

Primary sources:

- ASTRA code in `src/state.jl`, `src/residuals.jl`, `src/structure_equations.jl`, `src/jacobians.jl`, `src/solvers/*.jl`
- ASTRA docs in `docs/website/numerics/*.md`
- Stellax `methods/index.md` for pedagogical structure only

Each methods page must describe the exact ASTRA implementation, not a future target.

Do not duplicate large chunks of prose between methods pages. Cross-link instead.

**Step 4: Run test to verify it passes**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_docs_structure.jl")'
```

Expected: PASS with the methods-page contract checks satisfied.

**Step 5: Commit**

```bash
git add docs/website/methods test/test_docs_structure.jl
git commit -m "Add ASTRA methods reference pages"
```

### Task 6: Add the MESA Reference Subtree with File-Backed Comparisons

**Files:**
- Modify: `docs/website/methods/mesa-reference/index.md`
- Modify: `docs/website/methods/mesa-reference/solver-scaling.md`
- Modify: `docs/website/methods/mesa-reference/boundary-conditions.md`
- Modify: `docs/website/methods/mesa-reference/mesh-and-variables.md`
- Modify: `test/test_docs_structure.jl`

**Step 1: Write the failing test**

Add contract assertions requiring:

- `methods/mesa-reference/index.md`
  - `"file-backed parity"`
  - `"partial parity"`
  - `"analogy only"`
- `solver-scaling.md`
  - `"solver_support.f90"`
  - `"x_scale"`
  - `"correction_weight"`
- `boundary-conditions.md`
  - `"L_center"`
  - `"R_center"`
  - `"auto_diff_support.f90"`
- `mesh-and-variables.md`
  - `"star_data_step_input.inc"`
  - `"star_data_step_work.inc"`
  - `"i_lum"`

**Step 2: Run test to verify it fails**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_docs_structure.jl")'
```

Expected: FAIL because the MESA reference pages do not yet contain file-backed comparison content.

**Step 3: Write minimal implementation**

Ground every page directly in the local MESA source tree:

- `/Users/anna/projects/jaxstro-dev/legacy/stellax-legacy/reference/mesa/star/private/solver_support.f90`
- `/Users/anna/projects/jaxstro-dev/legacy/stellax-legacy/reference/mesa/star/private/auto_diff_support.f90`
- `/Users/anna/projects/jaxstro-dev/legacy/stellax-legacy/reference/mesa/star_data/public/star_data_step_input.inc`
- `/Users/anna/projects/jaxstro-dev/legacy/stellax-legacy/reference/mesa/star_data/public/star_data_step_work.inc`

For each comparison claim, label it explicitly as:

- file-backed parity,
- partial parity,
- analogy only,
- or not yet proven.

Do not rely on prior AI summaries as evidence.

**Step 4: Run test to verify it passes**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_docs_structure.jl")'
```

Expected: PASS with the MESA-reference contracts satisfied.

**Step 5: Commit**

```bash
git add docs/website/methods/mesa-reference test/test_docs_structure.jl
git commit -m "Add MESA-backed methods reference docs"
```

### Task 7: Final Integration, Cross-Links, and Full Verification

**Files:**
- Modify as needed: all touched `docs/website/physics/**`
- Modify as needed: all touched `docs/website/methods/**`
- Modify as needed: `docs/website/myst.yml`
- Modify as needed: `test/test_docs_structure.jl`

**Step 1: Write the failing test**

Add final docs-contract checks requiring:

- `physics` pages link into `methods`,
- `methods` pages link back into `physics`,
- MESA reference pages are linked from the relevant methods pages,
- and the old `numerics` concepts are either migrated or clearly routed to the new methods pages without duplicating conflicting canonical explanations.

Keep these checks narrow and string-based; do not try to test every link exhaustively here because Myst already handles link validation.

**Step 2: Run test to verify it fails**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Test, ASTRA; include("test/test_docs_structure.jl")'
```

Expected: FAIL until the final cross-linking and canonical-routing text is in place.

**Step 3: Write minimal implementation**

- add the final reciprocal links,
- ensure the hub pages and methods pages agree on terminology,
- ensure the exact public-current caveats stay consistent with ASTRA code,
- and verify no page accidentally inherits Stellax claims that exceed current ASTRA scope.

**Step 4: Run full verification**

Run:

```bash
~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
~/.juliaup/bin/julia --project=. scripts/run_examples.jl
cd docs/website && myst build --site --html --strict
```

Expected:

- `Pkg.test()` PASS,
- examples PASS,
- strict Myst build PASS,
- no docs-structure regressions.

**Step 5: Commit**

```bash
git add docs/website test/test_docs_structure.jl
git commit -m "Expand ASTRA physics and methods docs"
```
