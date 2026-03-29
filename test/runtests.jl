using Test
using ASTRA

@testset "ASTRA bootstrap" begin
    include("test_constants.jl")
    include("test_types.jl")
    include("test_grid.jl")
    include("test_state.jl")
    include("test_microphysics_interfaces.jl")
    include("test_boundary_conditions.jl")
    include("test_residual_scaffold.jl")
    include("test_jacobian_scaffold.jl")
    include("test_docs_structure.jl")
end
