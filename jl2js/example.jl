
@Base.ccallable Float64 myabs(x::Float64) = abs(x)

# @Base.ccallable Float64 myfun(x::Float64) = sum([abs(x), asin(x), tan(x)])

@Base.ccallable Float64 myfuna(x::Vector{Float64}) = sum(x)

@Base.ccallable Float64 myfun(x::Float64) = sum(Float64[x, x, 1.0])
