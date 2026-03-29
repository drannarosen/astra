@testset "docs structure" begin
    root = normpath(joinpath(@__DIR__, ".."))
    expected = [
        "docs/website/myst.yml",
        "docs/website/index.md",
        "docs/website/getting-started/installation.md",
        "docs/website/getting-started/quickstart.md",
        "docs/website/getting-started/developer-setup.md",
        "docs/website/architecture/overview.md",
        "docs/website/architecture/package-layout.md",
        "docs/website/architecture/data-model.md",
        "docs/website/architecture/solver-architecture.md",
        "docs/website/architecture/differentiability-strategy.md",
        "docs/website/architecture/formulation-interface.md",
        "docs/website/physics/stellar-structure.md",
        "docs/website/physics/eos.md",
        "docs/website/physics/opacity.md",
        "docs/website/physics/nuclear.md",
        "docs/website/physics/convection.md",
        "docs/website/physics/boundary-conditions.md",
        "docs/website/numerics/residuals.md",
        "docs/website/numerics/jacobians.md",
        "docs/website/numerics/nonlinear-solvers.md",
        "docs/website/numerics/linear-solvers.md",
        "docs/website/numerics/timestepping.md",
        "docs/website/numerics/diagnostics.md",
        "docs/website/formulations/classical-baseline.md",
        "docs/website/formulations/entropy-dae.md",
        "docs/website/formulations/method-comparison.md",
        "docs/website/tutorials/first-hydrostatic-model.md",
        "docs/website/tutorials/reading-the-codebase.md",
        "docs/website/tutorials/adding-a-microphysics-module.md",
        "docs/website/validation/philosophy.md",
        "docs/website/validation/hydrostatic-tests.md",
        "docs/website/validation/jacobian-checks.md",
        "docs/website/validation/solar-validation-ladder.md",
        "docs/website/validation/benchmark-plan.md",
        "docs/website/planning/roadmap.md",
        "docs/website/planning/milestones.md",
        "docs/website/planning/design-principles.md",
        "docs/website/planning/solar-first-strategy.md",
        "docs/website/planning/julia-dependency-strategy.md",
        "docs/website/planning/differentiable-astra-roadmap.md",
        "docs/website/planning/migration-notes-from-stellax.md",
        "docs/website/development/development-guide.md",
        "docs/website/development/checklists.md",
        "docs/website/development/checklists/solar-first-lane.md",
        "docs/website/development/progress-summary.md",
        "docs/website/development/changelog.md",
        "docs/website/development/backlog.md",
        "docs/website/development/issues.md",
        "docs/website/contributing/contributing.md",
        "docs/website/contributing/coding-style.md",
        "docs/website/contributing/testing.md",
        "docs/website/contributing/documentation-style.md",
        "docs/website/glossary.md",
    ]

    @test all(path -> isfile(joinpath(root, path)), expected)

    contract_docs = Dict(
        "docs/website/getting-started/quickstart.md" => [
            "`StellarModel`",
            "result.state.structure",
            "result.state.composition",
        ],
        "docs/website/tutorials/first-hydrostatic-model.md" => [
            "result.state.structure",
            "result.state.composition",
            "result.state.evolution",
        ],
        "docs/website/tutorials/reading-the-codebase.md" => [
            "`StellarModel`",
            "`StructureState`",
            "`CompositionState`",
            "`EvolutionState`",
        ],
        "docs/website/architecture/contracts-overview.md" => [
            "`StellarModel`",
            "current public contract",
        ],
        "docs/website/architecture/state-ownership.md" => [
            "`StellarModel`",
            "internal transitional scaffold",
        ],
        "docs/website/architecture/differentiability-strategy.md" => [
            "solution map",
            "implicit-function-theorem view",
            "backend-agnostic",
        ],
        "docs/website/development/progress-summary.md" => [
            "2026-03-29",
            "`StellarModel`",
            "Next step",
            "First classical residual minimal slice",
        ],
        "docs/website/development/checklists.md" => [
            "developer-facing checklists",
            "Current checklists",
            "Solar-First Lane Checklist",
        ],
        "docs/website/development/checklists/solar-first-lane.md" => [
            "Solar-First Lane Checklist",
            "Tier 0 structural sanity checks implemented",
            "Entropy-DAE comparison lane",
        ],
        "docs/website/physics/stellar-structure.md" => [
            "first classical residual",
            "not yet a validated solar model",
        ],
        "docs/website/physics/boundary-conditions.md" => [
            "shell-volume closure",
            "surface closure is still provisional",
        ],
        "docs/website/numerics/residuals.md" => [
            "first classical structure equations",
            "source-decomposed",
        ],
        "docs/website/physics/eos.md" => [
            "placeholder closure",
            "classical residual",
        ],
        "docs/website/physics/opacity.md" => [
            "classical residual",
            "placeholder closure",
        ],
        "docs/website/physics/convection.md" => [
            "criterion hook",
            "not yet a full transport theory",
        ],
        "docs/website/development/changelog.md" => [
            "first classical residual slice",
            "surface closure remains provisional",
            "differentiability strategy",
        ],
        "docs/website/development/backlog.md" => [
            "Next up",
            "Queued after that",
            "Not backlog items yet",
        ],
        "docs/website/planning/differentiable-astra-roadmap.md" => [
            "backend-agnostic",
            "classical baseline",
            "Entropy-DAE later",
        ],
        "docs/website/development/issues.md" => [
            "Active issues",
            "Classical residual convergence basin is still provisional",
            "Surface closure remains provisional",
            "Evolution remains intentionally stubbed",
        ],
    )

    for (path, needles) in contract_docs
        content = read(joinpath(root, path), String)
        @test all(needle -> occursin(needle, content), needles)
    end
end
