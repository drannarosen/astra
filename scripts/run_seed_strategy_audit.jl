using ASTRA

if length(ARGS) != 1
    error("expected exactly one output directory argument")
end

bundle = ASTRA.run_seed_strategy_audit(ARGS[1])

println(bundle.manifest_path)
