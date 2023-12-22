module ChaoticStrangeAttractors

export attract!, Attractor, AttractorSet, cycle_colors, Instantiate,
       Rossler, Lorenz, Aizawa

using Printf
using GLMakie
using .Iterators: peel

const interval = 0.05

struct Instantiate
    t::Float64
end

mutable struct State
    segments::Lines{Tuple{Vector{Point{3, Float32}}}}
    position::Scatter{Tuple{Vector{Point{3, Float32}}}}
    axis::Axis3
    colors::Tuple{RGBf, RGBf}
    init::Bool
    timers::Tuple{Timer, Timer}
    paused::Observable{Bool}
    function State()
        state = new()
        state.init = false
        state.paused = true
        return state
    end
    function State(segments, position, axis, colors, init, timers, paused)
        new(segments, position, axis, colors, init, timers, paused)
    end
end

include("Attractors.jl")
include("Overload.jl")

@kwdef mutable struct Colors
    palette::Vector{RGBf} = [
        RGBf(0.0, 0.0, 0.8), # ~ blue
        RGBf(0.0, 0.8, 0.0), # ~ green
        RGBf(0.8, 0.0, 0.0), # ~ red
        RGBf(0.8, 0.0, 0.8), # ~ magenta
        RGBf(0.0, 0.8, 0.8), # ~ cyan
    ]
    selection::Tuple{Int, Int} = (1, 3)
    fixed::Bool = false
end

const cycle_colors = Colors()

function (cycle::Colors)()
    cycle.fixed && return
    len = length(cycle.palette)
    line_selection = mod(cycle.selection[1], len) + 1
    point_selection = mod(line_selection, len - 1) + 2
    cycle.selection = (line_selection, point_selection)
end

function unroll!(attractor!::Attractor)
    (; segments, position, axis, colors) = attractor!.state
    for i = 1:div(interval, attractor!.dt)
        attractor!()
    end
    delete!(axis, segments)
    delete!(axis, position)
    segments = lines!(axis, attractor!.points...; color = colors[1])
    position = scatter!(axis, last.(attractor!.points)...; color = colors[2])
    attractor!.state.segments = segments
    attractor!.state.position = position
    return
end

function unroll!(attractor_set::AttractorSet)
    attractors = attractor_set.attractor
    for attractor ∈ attractors
        unroll!(attractor)
    end
end

function init!(attractor::Attractor)
    attractor.state.init && return
    (; x, y, z, fig, state) = attractor
    (; axis) = state
    (; palette, selection) = cycle_colors
    colors = ntuple(i -> palette[selection[i]], 2)
    cycle_colors()
    segments = lines!(axis, attractor.points...; color = colors[1])
    position = scatter!(axis, x, y, z; color = colors[2])
    init = true
    for (name, value) ∈ pairs((; segments, position, colors, init))
        setfield!(attractor.state, name, value)
    end
    return attractor
end

function init!(attractors::Vector{<:Attractor})
    initial, links = peel(attractors)
    init!(initial)
    for attractor ∈ links
        attractor.state.init && continue
        attractor.fig = initial.fig
        attractor.state.axis = initial.state.axis
        init!(attractor)
    end
    T = eltype(attractors)
    attractors = AttractorSet{T}(attractors, initial.fig, initial.state)
    return attractors
end

function set!(attractors::Attractors)
    attractor = attractors[]
    (; fig) = attractor
    T = typeof(attractor)
    if !attractor.state.init
        attractor.state.axis = Axis3(fig[1,1]; title = "$T attractor")
    end
    attractors = init!(attractors)
    display(GLMakie.Screen(), fig)
    return attractors
end

function pause(attractor::Attractor, state::Bool = !attractor.state.paused[])
    attractor.state.paused[] = state
end

function set_timers(attractor::Attractor, t::Real)
    t1 = Timer(_ -> unroll!(attractor), 0; interval)
    t2 = Timer(_ -> t ≠ Inf ? stop_timers(attractor) : nothing, t)
    attractor.state.timers = (t1, t2)
end

function stop_timers(attractor::Attractor)
    close.(attractor.state.timers)
end

function attract!(attractors::Attractors = Rossler();
                  t::Real = 125, paused::Bool = false)
    attractors = set!(attractors)
    (; fig) = attractors
    pause(attractors, paused)
    onmouserightup(_ -> pause(attractors), addmouseevents!(fig.scene))
    on(attractors.state.paused) do paused
        paused ? stop_timers(attractors) : set_timers(attractors, t)
    end
    on(events(fig).window_open) do window_open
        !attractors.state.paused[] && !window_open && pause(attractors, true)
    end
    paused || set_timers(attractors, t)
    return attractors
end

function attract!(attractors::Attractors, time::Instantiate)
    (; t) = time
    for attractor ∈ attractors, _ ∈ 1:t÷attractor.dt
        attractor()
    end
    attract!(attractors; paused = true)
end

function attract!(
    file_path  :: String,
    attractors :: Attractors = Aizawa();
    t          :: Real       = 125
)
    attractors = set!(attractors)
    T = eltype(attractors)
    (; fig) = attractors
    itr = range(1, t / interval)
    duration = @sprintf("%.2f", t / 60)
    @info "Encoding the $T attractor to $file_path, \
        this will take approximately $duration minutes."
    record(fig, file_path; visible = true, framerate = 20) do io
        for i in itr
            unroll!(attractors)
            !events(fig).window_open[] && break
            recordframe!(io)
        end
    end
    return attractors
end

end
