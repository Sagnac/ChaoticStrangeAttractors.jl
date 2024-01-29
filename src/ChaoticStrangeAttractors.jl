module ChaoticStrangeAttractors

export attract!, Attractor, cycle_colors, Instantiate,
       Rossler, Lorenz, Aizawa, Sprott, Thomas, Halvorsen, DoubleScroll, WINDMI, Chua

using Printf
using GLMakie
using .Iterators: peel

const interval = 0.05

struct Instantiate
    t::Float64
end

mutable struct State
    segments::Lines{Tuple{Vector{Point3f}}}
    position::Scatter{Tuple{Vector{Point3f}}}
    axis::Axis3
    colors::Tuple{RGBf, RGBf}
    timers::Vector{Timer}
    paused::Observable{Bool}
    function State()
        state = new()
        state.timers = [Timer(0.0) for i = 1:2]
        state.paused = true
        return state
    end
    function State(segments, position, axis, colors, timers, paused)
        new(segments, position, axis, colors, timers, paused)
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
    segments = lines!(axis, attractor!.points; color = colors[1])
    position = scatter!(axis, last(attractor!.points); color = colors[2])
    attractor!.state.segments = segments
    attractor!.state.position = position
    return
end

function unroll!(attractors::Vector{<:Attractor})
    for attractor ∈ attractors
        unroll!(attractor)
    end
end

function init!(attractor::Attractor)
    (; x, y, z, fig, state) = attractor
    (; axis) = state
    (; palette, selection) = cycle_colors
    colors = ntuple(i -> palette[selection[i]], 2)
    cycle_colors()
    segments = lines!(axis, attractor.points; color = colors[1])
    position = scatter!(axis, x, y, z; color = colors[2])
    for (name, value) ∈ pairs((; segments, position, colors))
        setfield!(attractor.state, name, value)
    end
    return
end

function init!(attractors::Vector{<:Attractor})
    initial, links = peel(attractors)
    init!(initial)
    for attractor ∈ links
        attractor.fig = initial.fig
        attractor.state.axis = initial.state.axis
        attractor.state.timers = initial.state.timers
        init!(attractor)
    end
    return
end

function set!(attractors::AttractorSet)
    attractor = attractors[]
    fig = Figure()
    attractor.fig = fig
    T = eltype(attractors)
    if T == Attractor
        title = join(attractors .|> typeof |> union, ", ") * " attractors"
    else
        title = "$T attractor"
    end
    attractor.state.axis = Axis3(fig[1,1]; title)
    init!(attractors)
    display(GLMakie.Screen(), fig)
    return title
end

function pause(attractor::Attractor, state::Bool = !attractor.state.paused[])
    attractor.state.paused[] = state
end

function start_timers(attractors::AttractorSet, t::Real)
    attractor = attractors[]
    attractor.state.timers[1] = Timer(_ -> unroll!(attractors), 0; interval)
    attractor.state.timers[2] = Timer(t) do _
        t ≠ Inf ? pause(attractor, true) : nothing
    end
end

function stop_timers(attractor::Attractor)
    close.(attractor.state.timers)
end

function attract!(attractors::AttractorSet = Rossler();
                  t::Real = 125, paused::Bool = false)
    set!(attractors)
    attractor = attractors[]
    (; fig) = attractor
    for attractor ∈ attractors
        attractor.state.paused = paused
    end
    onmouserightup(_ -> pause(attractor), addmouseevents!(fig.scene))
    on(attractor.state.paused) do paused
        paused ? stop_timers(attractor) : start_timers(attractors, t)
    end
    on(events(fig).window_open) do window_open
        !attractor.state.paused[] && !window_open && pause(attractor, true)
    end
    paused || start_timers(attractors, t)
    return attractors
end

function attract!(attractors::AttractorSet, time::Instantiate)
    (; t) = time
    for attractor ∈ attractors, _ ∈ 1:t/attractor.dt
        attractor()
    end
    attract!(attractors; paused = true)
end

function attract!(
    file_path  :: String,
    attractors :: AttractorSet = Aizawa();
    t          :: Real       = 125
)
    title = set!(attractors)
    attractor = attractors[]
    (; fig) = attractor
    itr = range(1, t / interval)
    duration = @sprintf("%.2f", t / 60)
    @info "Encoding the $title to $file_path, \
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
