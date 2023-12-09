module Rossler

export attract!, Attractor

using GLMakie

@kwdef mutable struct Attractor
     a::Float64 =  0.1
     b::Float64 =  0.1
     c::Float64 = 18.0
     x::Float64 = 21.0
     y::Float64 =  0.0
     z::Float64 =  0.0
    dt::Float64 =  0.05
    fig::Figure = Figure()
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
    (; a, b, c, x, y, z) = attractor
    fig = Figure()
    axis = Axis3(fig[1,1]; title = "Rössler attractor")
    fontsize = 16
    halign = :left
    grid = GridLayout(fig[1,2]; tellheight = false)
    Label(grid[1,1], L"a = %$a";   fontsize, halign)
    Label(grid[2,1], L"b = %$b";   fontsize, halign)
    Label(grid[3,1], L"c = %$c";   fontsize, halign)
    Label(grid[4,1], L"x_0 = %$x"; fontsize, halign)
    Label(grid[5,1], L"y_0 = %$y"; fontsize, halign)
    Label(grid[6,1], L"z_0 = %$z"; fontsize, halign)
    play = Button(grid[7,1]; label = "\u23ef", fontsize)
    colsize!(fig.layout, 1, Aspect(1, 1.0))
    local t1, t2
    function start_timers()
        t1 = Timer(_ -> evolve!(attractor, axis), 0; interval = attractor.dt)
        t2 = Timer(_ -> t ≠ Inf ? close_timers() : nothing, t)
    end
    close_timers() = (close(t1); close(t2))
    attractor.fig = fig
    screen = display(GLMakie.Screen(), fig)
    paused = false
    on(play.clicks; update = true) do _
        paused ? close_timers() : start_timers()
        paused = !paused
    end
    on(window_open -> !window_open && close_timers(), events(fig).window_open)
    return attractor
end

Base.display(::Attractor) = ()

end
