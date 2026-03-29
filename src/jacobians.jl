_radius_face_index(grid::StellarGrid, k::Int) = k

_luminosity_face_index(grid::StellarGrid, k::Int) = grid.n_cells + 1 + k

_temperature_cell_index(grid::StellarGrid, k::Int) = 2 * (grid.n_cells + 1) + k

_density_cell_index(grid::StellarGrid, k::Int) = 2 * (grid.n_cells + 1) + grid.n_cells + k

function jacobian_column_step(
    values::AbstractVector{<:Real},
    column::Int,
    base_step::Real,
)
    return max(abs(Float64(values[column])), 1.0) * Float64(base_step)
end

function _perturbed_model(
    model::StellarModel,
    column::Int,
    step::Real,
)
    trial_vector = pack_state(model.structure)
    trial_vector[column] += jacobian_column_step(trial_vector, column, step)
    trial_structure = unpack_state(model.structure, trial_vector)
    return StellarModel(trial_structure, model.composition, model.evolution)
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
        trial_model = _perturbed_model(model, column, step)
        trial_block = block_builder(problem, trial_model)
        jacobian[row_range, column] = (trial_block .- base_block) ./ column_step
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

    center_rows = structure_center_row_range()
    center_columns = Int[
        _radius_face_index(problem.grid, 1),
        _luminosity_face_index(problem.grid, 1),
        _temperature_cell_index(problem.grid, 1),
        _density_cell_index(problem.grid, 1),
    ]
    center_block = center_boundary_residual(problem, model)
    _fill_block_jacobian!(
        jacobian,
        center_rows,
        center_columns,
        problem,
        model,
        center_block,
        center_boundary_residual;
        step = step,
    )

    for k in 1:(n - 1)
        row_range = interior_structure_row_range(k)
        local_columns = Int[
            _radius_face_index(problem.grid, k),
            _radius_face_index(problem.grid, k + 1),
            _luminosity_face_index(problem.grid, k),
            _luminosity_face_index(problem.grid, k + 1),
            _temperature_cell_index(problem.grid, k),
            _temperature_cell_index(problem.grid, k + 1),
            _density_cell_index(problem.grid, k),
            _density_cell_index(problem.grid, k + 1),
        ]
        block_builder(problem, trial_model) = interior_structure_block(problem, trial_model, k)
        local_block = block_builder(problem, model)
        _fill_block_jacobian!(
            jacobian,
            row_range,
            local_columns,
            problem,
            model,
            local_block,
            block_builder;
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
