module Rossler

export attract!, Attractor

using Printf
using GLMakie

abstract type Attractor end

@kwdef mutable struct _Rossler <: Attractor
     a::Float64 =  0.1
     b::Float64 =  0.1
     c::Float64 = 18.0
     x::Float64 = 21.0
     y::Float64 =  0.0
     z::Float64 =  0.0
    dt::Float64 =  0.05
    fig::Figure = Figure()
end

@kwdef mutable struct Colors
    colors::Vector{RGBf} = [
        RGBf(0.0, 0.0, 0.8), # ~ blue
        RGBf(0.0, 0.8, 0.0), # ~ green
        RGBf(0.8, 0.0, 0.0), # ~ red
        RGBf(0.8, 0.0, 0.8), # ~ magenta
        RGBf(0.0, 0.8, 0.8), # ~ cyan
    ]
    selection::Int = 1
end

const cycle_colors = Colors()

function (cycle::Colors)()
    cycle.selection = mod(cycle.selection, 5) + 1
end

macro evolve!()
    quote
        x′ = x + dx_dt * dt
        y′ = y + dy_dt * dt
        z′ = z + dz_dt * dt
        lines!(axis, [x, x′], [y, y′], [z, z′]; color)
        attractor.x = x′
        attractor.y = y′
        attractor.z = z′
    end |> esc
end

function (attractor::_Rossler)(axis::Makie.AbstractAxis, color::RGBf)
    (; a, b, c) = attractor
    (; x, y, z, dt) = attractor
    dx_dt = -y - z
    dy_dt = x + a * y
    dz_dt = b + z * (x - c)
    @evolve!
    return
end

function attract!(attractor::T = _Rossler(); t::Real = 125) where T <: Attractor
    (; x, y, z) = attractor
    (; colors, selection) = cycle_colors
    fig = Figure()
    axis = Axis3(fig[1,1]; title = "$T attractor")
    fontsize = 16
    grid = GridLayout(fig[1,2]; tellheight = false)
    params = Makie.LaTeXString[]
    for name ∈ fieldnames(T)
        name == :x && break
        push!(params, L"%$name = %$(getfield(attractor, name))")
    end
    labels = [params; L"x_0 = %$x"; L"y_0 = %$y"; L"z_0 = %$z"]
    for i = 1:length(labels)
        Label(grid[i,1], labels[i]; fontsize, halign = :left)
    end
    play = Button(grid[7,1]; label = "\u23ef", fontsize)
    colsize!(fig.layout, 1, Aspect(1, 1.0))
    color = colors[selection]
    cycle_colors()
    local t1, t2
    function start_timers()
        t1 = Timer(_ -> attractor(axis, color), 0; interval = attractor.dt)
        t2 = Timer(_ -> t ≠ Inf ? close_timers() : nothing, t)
    end
    close_timers() = (close(t1); close(t2))
    attractor.fig = fig
    on(window_open -> !window_open && close_timers(), events(fig).window_open)
    display(GLMakie.Screen(), fig)
    paused = false
    on(play.clicks; update = true) do _
        paused ? close_timers() : start_timers()
        paused = !paused
    end
    return attractor
end

function Base.display(attractor::T) where T <: Attractor
    events(attractor.fig).window_open[] && return
    for name ∈ fieldnames(T)
        name == :dt && break
        @printf("%s = %.3f\n", name, getfield(attractor, name))
    end
    isempty(attractor.fig.content) || display(GLMakie.Screen(), attractor.fig)
    return
end

end
