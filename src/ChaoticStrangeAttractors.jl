module ChaoticStrangeAttractors

export attract!, Attractor, Rossler, Lorenz, Aizawa

using Printf
using GLMakie

const interval = 0.05

mutable struct State
    position::Scatter{Tuple{Vector{Point{3, Float32}}}}
    segments::Lines{Tuple{Vector{Point{3, Float32}}}}
    axis::Axis3
    colors::Tuple{RGBf, RGBf}
end

@kwdef mutable struct Colors
    palette::Vector{RGBf} = [
        RGBf(0.0, 0.0, 0.8), # ~ blue
        RGBf(0.0, 0.8, 0.0), # ~ green
        RGBf(0.8, 0.0, 0.0), # ~ red
        RGBf(0.8, 0.0, 0.8), # ~ magenta
        RGBf(0.0, 0.8, 0.8), # ~ cyan
    ]
    line_selection::Int = 1
    point_selection::Int = 3
end

const cycle_colors = Colors()

function (cycle::Colors)()
    cycle.line_selection = mod(cycle.line_selection, 5) + 1
    cycle.point_selection = mod(cycle.line_selection, 4) + 2
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
    (; position, segments, axis, colors) = state
    for i = 1:div(interval, attractor!.dt)
        attractor!()
    end
    delete!(axis, segments)
    delete!(axis, position)
    segments = lines!(axis, attractor!.points...; color = colors[1])
    position = scatter!(axis, last.(attractor!.points)...; color = colors[2])
    state.segments = segments
    state.position = position
    return
end

function set!(attractor::T) where T <: Attractor
    (; x, y, z) = attractor
    (; palette, line_selection, point_selection) = cycle_colors
    attractor.points = ([x], [y], [z])
    fig = Figure()
    axis = Axis3(fig[1,1]; title = "$T attractor")
    colors = (palette[line_selection], palette[point_selection])
    cycle_colors()
    segments = lines!(axis, attractor.points...; color = colors[1])
    position = scatter!(axis, x, y, z; color = colors[2])
    state = State(position, segments, axis, colors)
    attractor.fig = fig
    return state
end

function set!(fig::Figure)
    play = Button(fig[1,2]; label = "\u23ef", fontsize = 16, tellheight = false)
    colsize!(fig.layout, 1, Aspect(1, 1.0))
    return play
end
    
function attract!(attractor::Attractor = Rossler(); t::Real = 125)
    state = set!(attractor)
    (; fig) = attractor
    play = set!(fig)
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

function attract!(file_path::String, attractor::T = Aizawa();
                  t::Real = 125) where T <: Attractor
    state = set!(attractor)
    (; fig) = attractor
    itr = range(1, t / interval)
    duration = @sprintf("%.2f", t / 60)
    @info "Encoding the $T attractor to $file_path, \
        this will take approximately $duration minutes."
    display(GLMakie.Screen(), fig)
    record(fig, file_path; visible = true, framerate = 20) do io
        for i in itr
            unroll!(attractor, state)
            !events(fig).window_open[] && break
            recordframe!(io)
        end
    end
    return attractor
end

function Base.display(attractor::T) where T <: Attractor
    (; fig) = attractor
    for name ∈ fieldnames(T)
        name == :dt && break
        name == :x && @printf("\nx_0 = %.4f\ny_0 = %.4f\nz_0 = %.4f\nΔt = %.4f\n\n",
            first.(attractor.points)..., attractor.dt)
        @printf("%s = %.4f\n", name, getfield(attractor, name))
    end
    (isempty(fig.content) || events(fig).window_open[]) && return
    display(GLMakie.Screen(), fig)
end

end
