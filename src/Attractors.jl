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
