using ASTRA

parameters = StellarParameters(mass_g = 1.98847e33)
composition = Composition(0.70, 0.28, 0.02)
grid = build_grid(parameters, GridConfig(n_cells = 12))
state = initialize_state(parameters, composition, grid)

println("Number of cells: ", grid.n_cells)
println("Packed state length: ", length(ASTRA.pack_state(state)))
println("Inner radius [cm]: ", exp(state.log_radius_face_cm[1]))
println("Outer radius [cm]: ", exp(state.log_radius_face_cm[end]))
