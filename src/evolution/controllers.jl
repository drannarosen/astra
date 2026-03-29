abstract type AbstractTimestepController end

struct FixedTimestepController <: AbstractTimestepController
    dt_s::Float64

    function FixedTimestepController(; dt_s::Real = 1.0e5)
        dt_s > 0.0 || throw(ArgumentError("dt_s must be positive."))
        return new(Float64(dt_s))
    end
end
