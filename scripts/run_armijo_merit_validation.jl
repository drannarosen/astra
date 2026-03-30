using ASTRA

output_dir = isempty(ARGS) ? joinpath(pwd(), "armijo-merit-validation") : ARGS[1]
bundle = ASTRA.run_armijo_merit_validation_suite(output_dir)

println(bundle.manifest_path)
