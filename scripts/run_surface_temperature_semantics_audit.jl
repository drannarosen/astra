using ASTRA

if length(ARGS) != 1
    error("expected exactly one output directory argument")
end

bundle = ASTRA.run_surface_temperature_semantics_audit(ARGS[1])

println(bundle.manifest_path)
