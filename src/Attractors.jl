abstract type Attractor end

@kwdef mutable struct Rossler <: Attractor
     a::Float64 =  0.1
     b::Float64 =  0.1
     c::Float64 = 18.0
     x::Float64 = 21.0
     y::Float64 =  0.0
     z::Float64 =  0.0
    dt::Float64 =  0.05
    fig::Figure = Figure()
end

function (attractor::Rossler)(axis::Makie.AbstractAxis, color::RGBf)
    (; a, b, c) = attractor
    (; x, y, z, dt) = attractor
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
     x::Float64 =  2.0
     y::Float64 =  1.0
     z::Float64 =  1.0
    dt::Float64 =  0.01
    fig::Figure = Figure()
end

function (attractor::Lorenz)(axis::Makie.AbstractAxis, color::RGBf)
    (; σ, ρ, β) = attractor
    (; x, y, z, dt) = attractor
    dx_dt = σ * (y - x)
    dy_dt = x * (ρ - z) - y
    dz_dt = x * y - β * z
    @evolve!
    return
end
