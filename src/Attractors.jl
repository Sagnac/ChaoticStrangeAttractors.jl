abstract type Attractor end

const Attractors = Union{Attractor, Vector{<:Attractor}}

@kwdef mutable struct Rossler <: Attractor
     a::Float64 =  0.1
     b::Float64 =  0.1
     c::Float64 = 18.0
     x::Float64 = 21.0
     y::Float64 =  0.0
     z::Float64 =  0.0
     t::Float64 =  0.0
    dt::Float64 =  0.001
    fig::Figure = Figure()
    points::Tuple{Vector{Float64}, Vector{Float64}, Vector{Float64}} = [x], [y], [z]
    state::State = State()
end

function (attractor!::Rossler)()
    (; a, b, c) = attractor!
    (; x, y, z, dt) = attractor!
    dx_dt = -y - z
    dy_dt = x + a * y
    dz_dt = b + z * (x - c)
    @evolve!
    return
end

@kwdef mutable struct Lorenz <: Attractor
     σ::Float64 = 10.0
     ρ::Float64 = 28.0
     β::Float64 =  8/3
     x::Float64 =  1.0
     y::Float64 =  0.0
     z::Float64 =  0.0
     t::Float64 =  0.0
    dt::Float64 =  0.001
    fig::Figure = Figure()
    points::Tuple{Vector{Float64}, Vector{Float64}, Vector{Float64}} = [x], [y], [z]
    state::State = State()
end

function (attractor!::Lorenz)()
    (; σ, ρ, β) = attractor!
    (; x, y, z, dt) = attractor!
    dx_dt = σ * (y - x)
    dy_dt = x * (ρ - z) - y
    dz_dt = x * y - β * z
    @evolve!
    return
end

@kwdef mutable struct Aizawa <: Attractor
     a::Float64 =  0.95
     b::Float64 =  0.7
     c::Float64 =  0.6
     d::Float64 =  3.5
     e::Float64 =  0.25
     f::Float64 =  0.1
     x::Float64 =  1.0
     y::Float64 =  0.0
     z::Float64 =  0.0
     t::Float64 =  0.0
    dt::Float64 =  0.001
    fig::Figure = Figure()
    points::Tuple{Vector{Float64}, Vector{Float64}, Vector{Float64}} = [x], [y], [z]
    state::State = State()
end

function (attractor!::Aizawa)()
    (; a, b, c, d, e, f) = attractor!
    (; x, y, z, dt) = attractor!
    dx_dt = (z - b)x - d*y
    dy_dt = d*x + (z - b)y
    dz_dt = c + a*z - z^3/3 - (x^2 + y^2)*(1 + e*z) + f*z*x^3
    @evolve!
    return
end
