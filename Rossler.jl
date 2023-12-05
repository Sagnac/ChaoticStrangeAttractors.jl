using GLMakie

@kwdef mutable struct Attractor
     a::Float64 =  0.1
     b::Float64 =  0.1
     c::Float64 = 18.0
     x::Float64 = 21.0
     y::Float64 =  0.0
     z::Float64 =  0.0
    dt::Float64 =  0.05
end

function evolve!(attractor::Attractor, axis::Makie.AbstractAxis)
    (; a, b, c, x, y, z, dt) = attractor
    dx_dt = -y - z
    dy_dt = x + a * y
    dz_dt = b + z * (x - c)
    x′ = x + dx_dt * dt
    y′ = y + dy_dt * dt
    z′ = z + dz_dt * dt
    lines!(axis, [x, x′], [y, y′], [z, z′]; color = RGBf(0.0, 0.0, 0.8))
    attractor.x = x′
    attractor.y = y′
    attractor.z = z′
    return
end

function attract!(attractor::Attractor = Attractor(); t::Real = 125)
    fig = Figure()
    axis = Axis3(fig[1,1]; title = "Rössler attractor")
    screen = display(fig)
    close_timers() = (close(t1); close(t2))
    t1 = Timer(_ -> evolve!(attractor, axis), 0; interval = attractor.dt)
    t2 = Timer(_ -> t ≠ Inf ? close_timers() : nothing, t)
    wait(screen)
    close_timers()
    return fig
end
