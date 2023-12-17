module ChaoticStrangeAttractors

export attract!, Attractor, Rossler, Lorenz, Aizawa

using Printf
using GLMakie

const interval = 0.05

mutable struct State
    position::Scatter{Tuple{Vector{Point{3, Float32}}}}
    segments::Lines{Tuple{Vector{Point{3, Float32}}}}
    axis::Axis3
    color::RGBf
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
        push!(attractor!.points[1], x′)
        push!(attractor!.points[2], y′)
        push!(attractor!.points[3], z′)
        attractor!.x = x′
        attractor!.y = y′
        attractor!.z = z′
        attractor!.t += dt
    end |> esc
end

include("Attractors.jl")

function unroll!(attractor!::Attractor, state::State)
    (; position, segments, axis, color) = state
    for i = 1:div(interval, attractor!.dt)
        attractor!()
    end
    delete!(axis, segments)
    delete!(axis, position)
    segments = lines!(axis, attractor!.points...; color)
    position = scatter!(axis, attractor!.x, attractor!.y, attractor!.z; color)
    state.segments = segments
    state.position = position
    return
end

function attract!(attractor::T = Rossler(); t::Real = 125) where T <: Attractor
    (; x, y, z) = attractor
    (; colors, selection) = cycle_colors
    attractor.points = [[x], [y], [z]]
    fig = Figure()
    axis = Axis3(fig[1,1]; title = "$T attractor")
    play = Button(fig[1,2]; label = "\u23ef", fontsize = 16, tellheight = false)
    colsize!(fig.layout, 1, Aspect(1, 1.0))
    color = colors[selection]
    cycle_colors()
    segments = lines!(axis, attractor.points...; color)
    position = scatter!(axis, x, y, z; color)
    state = State(position, segments, axis, color)
    attractor.fig = fig
    local t1, t2
    paused = true
    function start_timers()
        t1 = Timer(_ -> unroll!(attractor, state), 0; interval)
        t2 = Timer(_ -> t ≠ Inf ? stop_timers() : nothing, t)
        paused = false
    end
    function stop_timers()
        close(t1)
        close(t2)
        paused = true
    end
    on(window_open -> !window_open && stop_timers(), events(fig).window_open)
    display(GLMakie.Screen(), fig)
    on(play.clicks; update = true) do _
        paused ? start_timers() : stop_timers()
    end
    return attractor
end

function Base.display(attractor::T) where T <: Attractor
    (; fig) = attractor
    for name ∈ fieldnames(T)
        name == :fig && break
        @printf("%s = %.4f\n", name, getfield(attractor, name))
    end
    (isempty(fig.content) || events(fig).window_open[]) && return
    display(GLMakie.Screen(), fig)
end

end
