using ASTRA

if length(ARGS) != 1
    error("expected exactly one output directory argument")
end

bundle = ASTRA.run_surface_owner_localization_audit(ARGS[1])

println(bundle.manifest_path)
