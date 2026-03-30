_radius_face_index(grid::StellarGrid, k::Int) = k

_luminosity_face_index(grid::StellarGrid, k::Int) = grid.n_cells + 1 + k

_temperature_cell_index(grid::StellarGrid, k::Int) = 2 * (grid.n_cells + 1) + k

_density_cell_index(grid::StellarGrid, k::Int) = 2 * (grid.n_cells + 1) + grid.n_cells + k

function _center_columns(grid::StellarGrid)
    return Int[
        _radius_face_index(grid, 1),
        _luminosity_face_index(grid, 1),
        _temperature_cell_index(grid, 1),
        _density_cell_index(grid, 1),
    ]
end

function _interior_columns(grid::StellarGrid, k::Int)
    return Int[
        _radius_face_index(grid, k),
        _radius_face_index(grid, k + 1),
        _luminosity_face_index(grid, k),
        _luminosity_face_index(grid, k + 1),
        _temperature_cell_index(grid, k),
        _temperature_cell_index(grid, k + 1),
        _density_cell_index(grid, k),
        _density_cell_index(grid, k + 1),
    ]
end

function _center_radius_row_partials(problem::StructureProblem, model::StellarModel)
    partials = zeros(Float64, length(_center_columns(problem.grid)))
    partials[1] = exp(model.structure.log_radius_face_cm[1])
    partials[4] = center_radius_series_target_cm(problem, model) / 3.0
    return partials
end

function _center_luminosity_row_partials(problem::StructureProblem, model::StellarModel)
    enclosed_mass_g = problem.grid.m_face_g[1]
    dε_dlnT, dε_dlnρ = _centered_energy_source_log_derivatives(problem, model, 1)

    partials = zeros(Float64, length(_center_columns(problem.grid)))
    partials[2] = 1.0
    partials[3] = -enclosed_mass_g * dε_dlnT
    partials[4] = -enclosed_mass_g * dε_dlnρ
    return partials
end

function _geometry_row_partials(problem::StructureProblem, model::StellarModel, k::Int)
    r_left_cm = exp(model.structure.log_radius_face_cm[k])
    r_right_cm = exp(model.structure.log_radius_face_cm[k + 1])
    density_g_cm3 = exp(model.structure.log_density_cell_g_cm3[k])
    dm_g = problem.grid.dm_cell_g[k]

    partials = zeros(Float64, length(_interior_columns(problem.grid, k)))
    partials[1] = -4.0 * π * r_left_cm^3
    partials[2] = 4.0 * π * r_right_cm^3
    partials[7] = dm_g / clip_positive(density_g_cm3)
    return partials
end

function _luminosity_row_partials(problem::StructureProblem, model::StellarModel, k::Int)
    dm_g = problem.grid.dm_cell_g[k]
    dε_dlnT, dε_dlnρ = _centered_energy_source_log_derivatives(problem, model, k)

    partials = zeros(Float64, length(_interior_columns(problem.grid, k)))
    partials[3] = -1.0
    partials[4] = 1.0
    partials[5] = -dm_g * dε_dlnT
    partials[7] = -dm_g * dε_dlnρ
    return partials
end

function _perturb_structure_state(
    model::StellarModel,
    column::Int,
    delta::Real,
)
    values = pack_state(model.structure)
    values[column] += Float64(delta)
    return StellarModel(unpack_state(model.structure, values), model.composition, model.evolution)
end

function _centered_energy_source_log_derivatives(
    problem::StructureProblem,
    model::StellarModel,
    k::Int;
    step::Real = 1.0e-6,
)
    base_vector = pack_state(model.structure)
    temperature_column = _temperature_cell_index(problem.grid, k)
    density_column = _density_cell_index(problem.grid, k)

    temperature_step = jacobian_column_step(base_vector, temperature_column, step)
    density_step = jacobian_column_step(base_vector, density_column, step)

    temperature_plus = _perturb_structure_state(model, temperature_column, temperature_step)
    temperature_minus = _perturb_structure_state(model, temperature_column, -temperature_step)
    density_plus = _perturb_structure_state(model, density_column, density_step)
    density_minus = _perturb_structure_state(model, density_column, -density_step)

    eps_plus = cell_energy_source_state(problem, temperature_plus, k).eps_total_erg_g_s
    eps_minus = cell_energy_source_state(problem, temperature_minus, k).eps_total_erg_g_s
    dε_dlnT = (eps_plus - eps_minus) / (2.0 * temperature_step)

    eps_plus = cell_energy_source_state(problem, density_plus, k).eps_total_erg_g_s
    eps_minus = cell_energy_source_state(problem, density_minus, k).eps_total_erg_g_s
    dε_dlnρ = (eps_plus - eps_minus) / (2.0 * density_step)

    return dε_dlnT, dε_dlnρ
end

function _assign_row_partials!(
    jacobian::AbstractMatrix{<:Real},
    row::Int,
    columns::AbstractVector{<:Integer},
    partials::AbstractVector{<:Real},
)
    jacobian[row, columns] .= partials
    return jacobian
end

function _local_central_difference(
    problem::StructureProblem,
    model::StellarModel,
    row_builder::Function,
    columns::AbstractVector{<:Integer};
    step::Real,
)
    base_vector = pack_state(model.structure)
    jacobian = Matrix{Float64}(undef, length(row_builder(problem, model)), length(columns))

    for (j, column) in pairs(columns)
        column_step = jacobian_column_step(base_vector, column, step)

        perturbed_plus = copy(base_vector)
        perturbed_plus[column] += column_step
        plus_model = StellarModel(
            unpack_state(model.structure, perturbed_plus),
            model.composition,
            model.evolution,
        )

        perturbed_minus = copy(base_vector)
        perturbed_minus[column] -= column_step
        minus_model = StellarModel(
            unpack_state(model.structure, perturbed_minus),
            model.composition,
            model.evolution,
        )

        plus_residual = row_builder(problem, plus_model)
        minus_residual = row_builder(problem, minus_model)
        jacobian[:, j] = (plus_residual .- minus_residual) ./ (2.0 * column_step)
    end

    return jacobian
end

function _fidelity_summary(
    comparisons::Vector{Tuple{Matrix{Float64},Matrix{Float64}}},
)
    max_abs_error = 0.0
    max_rel_error = 0.0
    row_count = 0
    column_count = 0

    for (computed, reference) in comparisons
        errors = abs.(computed .- reference)
        scale = max.(1.0, abs.(reference))
        max_abs_error = max(max_abs_error, maximum(errors))
        max_rel_error = max(max_rel_error, maximum(errors ./ scale))
        row_count += size(computed, 1)
        column_count += size(computed, 2)
    end

    return (
        row_count = row_count,
        column_count = column_count,
        max_abs_error = max_abs_error,
        max_rel_error = max_rel_error,
    )
end

function jacobian_fidelity_audit(
    problem::StructureProblem,
    model::StellarModel;
    step::Real = problem.solver.finite_difference_step,
)
    jacobian = structure_jacobian(problem, model; step = step)
    center_columns = _center_columns(problem.grid)

    center_fd = _local_central_difference(
        problem,
        model,
        center_boundary_residual,
        center_columns;
        step = step,
    )
    center_matrix = jacobian[collect(structure_center_row_range()), center_columns]

    geometry_matrices = Tuple{Matrix{Float64},Matrix{Float64}}[]
    luminosity_matrices = Tuple{Matrix{Float64},Matrix{Float64}}[]
    hydrostatic_matrices = Tuple{Matrix{Float64},Matrix{Float64}}[]
    transport_matrices = Tuple{Matrix{Float64},Matrix{Float64}}[]

    for k in 1:(problem.grid.n_cells - 1)
        columns = _interior_columns(problem.grid, k)
        block_builder(problem, trial_model) = interior_structure_block(problem, trial_model, k)
        block_fd = _local_central_difference(problem, model, block_builder, columns; step = step)
        row_range = collect(interior_structure_row_range(k))
        block = jacobian[row_range, columns]
        push!(geometry_matrices, (reshape(block[1, :], 1, :), reshape(block_fd[1, :], 1, :)))
        push!(hydrostatic_matrices, (reshape(block[2, :], 1, :), reshape(block_fd[2, :], 1, :)))
        push!(luminosity_matrices, (reshape(block[3, :], 1, :), reshape(block_fd[3, :], 1, :)))
        push!(transport_matrices, (reshape(block[4, :], 1, :), reshape(block_fd[4, :], 1, :)))
    end

    return (
        center = _fidelity_summary([(center_matrix, center_fd)]),
        geometry = _fidelity_summary(geometry_matrices),
        luminosity = _fidelity_summary(luminosity_matrices),
        hydrostatic = _fidelity_summary(hydrostatic_matrices),
        transport = _fidelity_summary(transport_matrices),
    )
end

function jacobian_column_step(
    values::AbstractVector{<:Real},
    column::Int,
    base_step::Real,
)
    return max(abs(Float64(values[column])), 1.0) * Float64(base_step)
end

function _fill_block_jacobian!(
    jacobian::AbstractMatrix{<:Real},
    row_range,
    columns::AbstractVector{<:Integer},
    problem::StructureProblem,
    model::StellarModel,
    base_block::AbstractVector{<:Real},
    block_builder::Function;
    step::Real,
)
    base_vector = pack_state(model.structure)
    for column in columns
        column_step = jacobian_column_step(base_vector, column, step)
        plus_vector = copy(base_vector)
        plus_vector[column] += column_step
        plus_model = StellarModel(
            unpack_state(model.structure, plus_vector),
            model.composition,
            model.evolution,
        )
        minus_vector = copy(base_vector)
        minus_vector[column] -= column_step
        minus_model = StellarModel(
            unpack_state(model.structure, minus_vector),
            model.composition,
            model.evolution,
        )
        plus_block = block_builder(problem, plus_model)
        minus_block = block_builder(problem, minus_model)
        jacobian[row_range, column] = (plus_block .- minus_block) ./ (2.0 * column_step)
    end
    return jacobian
end

function structure_jacobian(
    problem::StructureProblem,
    model::StellarModel;
    step::Real = problem.solver.finite_difference_step,
)
    n = problem.grid.n_cells
    n_state = length(pack_state(model.structure))
    jacobian = zeros(Float64, n_state, n_state)

    center_rows = collect(structure_center_row_range())
    center_columns = _center_columns(problem.grid)
    _assign_row_partials!(
        jacobian,
        center_rows[1],
        center_columns,
        _center_radius_row_partials(problem, model),
    )
    _assign_row_partials!(
        jacobian,
        center_rows[2],
        center_columns,
        _center_luminosity_row_partials(problem, model),
    )

    for k in 1:(n - 1)
        row_range = interior_structure_row_range(k)
        local_columns = _interior_columns(problem.grid, k)
        block_builder(problem, trial_model) = interior_structure_block(problem, trial_model, k)
        local_block = block_builder(problem, model)
        _assign_row_partials!(
            jacobian,
            first(row_range),
            local_columns,
            _geometry_row_partials(problem, model, k),
        )
        _assign_row_partials!(
            jacobian,
            first(row_range) + 2,
            local_columns,
            _luminosity_row_partials(problem, model, k),
        )
        _fill_block_jacobian!(
            jacobian,
            [first(row_range) + 1, first(row_range) + 3],
            local_columns,
            problem,
            model,
            local_block[[2, 4]],
            (problem, trial_model) -> block_builder(problem, trial_model)[[2, 4]];
            step = step,
        )
    end

    surface_rows = structure_surface_row_range(n)
    surface_columns = Int[
        _radius_face_index(problem.grid, n + 1),
        _luminosity_face_index(problem.grid, n + 1),
        _temperature_cell_index(problem.grid, n),
        _density_cell_index(problem.grid, n),
    ]
    surface_block = surface_boundary_residual(problem, model)
    _fill_block_jacobian!(
        jacobian,
        surface_rows,
        surface_columns,
        problem,
        model,
        surface_block,
        surface_boundary_residual;
        step = step,
    )

    return jacobian
end

function finite_difference_jacobian(
    problem::StructureProblem,
    model::StellarModel;
    step::Real = problem.solver.finite_difference_step,
)
    base_vector = pack_state(model.structure)
    base_residual = assemble_structure_residual(problem, model)
    n = length(base_vector)
    jacobian = Matrix{Float64}(undef, length(base_residual), n)

    for j in 1:n
        perturbed = copy(base_vector)
        column_step = jacobian_column_step(base_vector, j, step)
        perturbed[j] += column_step
        trial_structure = unpack_state(model.structure, perturbed)
        trial_model = StellarModel(trial_structure, model.composition, model.evolution)
        trial_residual = assemble_structure_residual(problem, trial_model)
        jacobian[:, j] = (trial_residual .- base_residual) ./ column_step
    end

    return jacobian
end
