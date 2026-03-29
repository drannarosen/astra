const POSITIVE_FLOOR = 1.0e-99

clip_positive(value::Real) = max(Float64(value), POSITIVE_FLOOR)
positive_log(value::Real) = log(clip_positive(value))
