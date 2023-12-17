module ChaoticStrangeAttractors

export attract!, Attractor, Rossler, Lorenz, Aizawa

using Printf
using GLMakie

const interval = 0.05

mutable struct State
    point::Scatter{Tuple{Vector{Point{3, Float32}}}}
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
        push!(segments[1], x′)
        push!(segments[2], y′)
        push!(segments[3], z′)
        attractor!.x = x′
        attractor!.y = y′
        attractor!.z = z′
    end |> esc
end

include("Attractors.jl")

function unroll!(attractor!::Attractor, state::State)
    (; point, axis, color) = state
    segments = [[attractor!.x], [attractor!.y], [attractor!.z]]
    for i = 1:div(interval, attractor!.dt)
        attractor!(segments)
    end
    delete!(axis, point)
    lines!(axis, segments...; color)
    point = scatter!(axis, attractor!.x, attractor!.y, attractor!.z; color)
    state.point = point
    return
end

function format_labels(attractor::T) where T <: Attractor
    labels = Makie.LaTeXString[]
    subscript = false
    for name ∈ fieldnames(T)
        name == :fig && break
        subscript = subscript || name == :x
        latex_name = subscript ? string(name, "_0") : name
        if name == :dt
            latex_name = "Δt"
        end
        value = @sprintf("%.3f", getfield(attractor, name))
        push!(labels, L"%$latex_name = %$value")
    end
    return labels
end

function attract!(attractor::T = Rossler(); t::Real = 125) where T <: Attractor
    (; x, y, z) = attractor
    (; colors, selection) = cycle_colors
    fig = Figure()
    axis = Axis3(fig[1,1]; title = "$T attractor")
    fontsize = 16
    grid = GridLayout(fig[1,2]; tellheight = false)
    labels = format_labels(attractor)
    label_len = length(labels)
    for i = 1:label_len
        Label(grid[i,1], labels[i]; fontsize, halign = :left)
    end
    play = Button(grid[label_len+1,1]; label = "\u23ef", fontsize)
    colsize!(fig.layout, 1, Aspect(1, 1.0))
    color = colors[selection]
    cycle_colors()
    point = scatter!(axis, x, y, z; color)
    state = State(point, axis, color)
    local t1, t2
    function start_timers()
        t1 = Timer(_ -> unroll!(attractor, state), 0; interval)
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
