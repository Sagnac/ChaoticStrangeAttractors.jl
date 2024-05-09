abstract type Attractor end

const AttractorSet = Union{Attractor, Vector{<:Attractor}}

function evolve!(attractor)
    (; x, y, z, dt) = attractor
    r0 = (x, y, z)
    dt2 = dt * 0.5
    k1 = attractor(x, y, z)
    r1 = @. r0 + k1 * dt2
    k2 = attractor(r1...)
    r2 = @. r0 + k2 * dt2
    k3 = attractor(r2...)
    r3 = @. r0 + k3 * dt
    k4 = attractor(r3...)
    x4, y4, z4 = @. r0 + (k1 + 2k2 + 2k3 + k4) * dt / 6
    push!(attractor.points, Point3(x4, y4, z4))
    attractor.x = x4
    attractor.y = y4
    attractor.z = z4
    attractor.t += dt
end

macro fields()
    quote
         t::Float64 = 0.0
        dt::Float64 = 0.001
        fig::Figure = Figure()
        points::Vector{Point3{Float64}} = [Point3(x, y, z)]
        state::State = State()
    end |> esc
end

@kwdef mutable struct Rossler <: Attractor
    a::Float64 =  0.1
    b::Float64 =  0.1
    c::Float64 = 18.0
    x::Float64 = 21.0
    y::Float64 =  0.0
    z::Float64 =  0.0
    @fields
end

function (attractor::Rossler)(x, y, z)
    (; a, b, c) = attractor
    dx_dt = -y - z
    dy_dt = x + a * y
    dz_dt = b + z * (x - c)
    return dx_dt, dy_dt, dz_dt
end

@kwdef mutable struct Lorenz <: Attractor
    σ::Float64 = 10.0
    ρ::Float64 = 28.0
    β::Float64 =  8/3
    x::Float64 =  4.0
    y::Float64 =  7.0
    z::Float64 =  5.0
    @fields
end

function (attractor::Lorenz)(x, y, z)
    (; σ, ρ, β) = attractor
    dx_dt = σ * (y - x)
    dy_dt = x * (ρ - z) - y
    dz_dt = x * y - β * z
    return dx_dt, dy_dt, dz_dt
end

@kwdef mutable struct Aizawa <: Attractor
    a::Float64 = 0.95
    b::Float64 = 0.7
    c::Float64 = 0.6
    d::Float64 = 3.5
    e::Float64 = 0.25
    f::Float64 = 0.1
    x::Float64 = 1.0
    y::Float64 = 0.0
    z::Float64 = 0.0
    @fields
end

function (attractor::Aizawa)(x, y, z)
    (; a, b, c, d, e, f) = attractor
    dx_dt = (z - b)x - d*y
    dy_dt = d*x + (z - b)y
    dz_dt = c + a*z - z^3/3 - (x^2 + y^2)*(1 + e*z) + f*z*x^3
    return dx_dt, dy_dt, dz_dt
end

@kwdef mutable struct Sprott <: Attractor
    a::Float64 = 2.0
    b::Float64 = 2.0
    x::Float64 = 1.0
    y::Float64 = 0.0
    z::Float64 = 0.0
    @fields
end

function (attractor::Sprott)(x, y, z)
    (; a, b) = attractor
    dx_dt = y + a*x*y + x*z
    dy_dt = 1 - b*x^2 + y*z
    dz_dt = x - x^2 - y^2
    return dx_dt, dy_dt, dz_dt
end

@kwdef mutable struct Thomas <: Attractor
    b::Float64 = 0.18
    x::Float64 = 0.3
    y::Float64 = 0.0
    z::Float64 = 0.0
    @fields
end

function (attractor::Thomas)(x, y, z)
    (; b) = attractor
    dx_dt = sin(y) - b * x
    dy_dt = sin(z) - b * y
    dz_dt = sin(x) - b * z
    return dx_dt, dy_dt, dz_dt
end

@kwdef mutable struct Halvorsen <: Attractor
    a::Float64 =  1.3
    b::Float64 =  4.0
    x::Float64 = -5.0
    y::Float64 =  0.0
    z::Float64 =  0.0
    @fields
end

function (attractor::Halvorsen)(x, y, z)
    (; a, b) = attractor
    dx_dt = -a * x - b * (y + z) - y^2
    dy_dt = -a * y - b * (z + x) - z^2
    dz_dt = -a * z - b * (x + y) - x^2
    return dx_dt, dy_dt, dz_dt
end

@kwdef mutable struct DoubleScroll <: Attractor
    a::Float64 = 0.8
    x::Float64 = 0.01
    y::Float64 = 0.01
    z::Float64 = 0.00
    @fields
end

function (attractor::DoubleScroll)(x, y, z)
    (; a) = attractor
    dx_dt = y
    dy_dt = z
    dz_dt = -a * (z + y + x - sign(x))
    return dx_dt, dy_dt, dz_dt
end

@kwdef mutable struct WINDMI <: Attractor
    a::Float64 = 0.7
    b::Float64 = 2.5
    x::Float64 = 0.0
    y::Float64 = 0.8
    z::Float64 = 0.0
    @fields
end

function (attractor::WINDMI)(x, y, z)
    (; a, b) = attractor
    dx_dt = y
    dy_dt = z
    dz_dt = -a * z - y + b - exp(x)
    return dx_dt, dy_dt, dz_dt
end

@kwdef mutable struct Chua <: Attractor
    α::Float64 =   9.0
    β::Float64 = 100/7
    a::Float64 =   8/7
    b::Float64 =   5/7
    x::Float64 =   0.0
    y::Float64 =   0.0
    z::Float64 =   0.7
    @fields
end

function (attractor::Chua)(x, y, z)
    (; a, b, α, β) = attractor
    dx_dt = α * (y - x + b * x + 0.5(a - b) * (abs(x + 1) - abs(x - 1)))
    dy_dt = x - y + z
    dz_dt = -β * y
    return dx_dt, dy_dt, dz_dt
end
