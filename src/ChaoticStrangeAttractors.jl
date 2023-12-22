module ChaoticStrangeAttractors

export attract!, Attractor, AttractorSet, cycle_colors, Rossler, Lorenz, Aizawa

using Printf
using GLMakie
using .Iterators: peel

const interval = 0.05

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
    return attractors, T
end

function set_timers(attractor::Attractor, t)
    t1 = Timer(_ -> unroll!(attractor), 0; interval)
    t2 = Timer(_ -> t ≠ Inf ? stop_timers() : nothing, t)
    attractor.state.timers = (t1, t2)
    attractor.state.paused[] = false
end

function stop_timers(attractor::Attractor)
    close.(attractor.state.timers)
    attractor.state.paused[] = true
end

function attract!(attractors::Attractors = Rossler();
                  t::Real = 125, paused::Bool = false)
    attractors, = set!(attractors)
    (; fig) = attractors
    on(events(fig).window_open) do window_open
        !paused && !window_open && stop_timers(attractors)
    end
    paused || set_timers(attractors, t)
    return attractors
end

function attract!(
    file_path  :: String,
    attractors :: Attractors = Aizawa();
    t          :: Real       = 125
)
    attractors, T = set!(attractors)
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

function recap(io::IO, attractor::T) where T <: Attractor
    (; fig) = attractor
    print(io, T, " attractor:")
    for name ∈ fieldnames(T)
        name == :dt && break
        if name == :x
            @printf(io, "\n\nx_0 = %.4f\ny_0 = %.4f\nz_0 = %.4f\nΔt = %.4f\n",
                first.(attractor.points)..., attractor.dt)
        end
        @printf(io, "\n%s = %.4f", name, getfield(attractor, name))
    end
    (isempty(fig.content) || events(fig).window_open[]) && return
    display(GLMakie.Screen(), fig)
end

function show_params(io::IO, attractor::T) where T <: Attractor
    for name ∈ fieldnames(T)
        name == :x && break
        @printf(io, "%s = %.4f, ", name, getfield(attractor, name))
    end
    @printf(io, "x_0 = %.4f, y_0 = %.4f, z_0 = %.4f", first.(attractor.points)...)
end

function Base.show(io::IO, attractor::Attractor)
    f = get(io, :typeinfo, false) isa Type ? show_params : recap
    f(io, attractor)
end

function Base.display(attractor_set::T) where T <: AttractorSet
    (; attractor, fig, state) = attractor_set
    if state.paused[]
        println(T, " attractor field:")
        show(stdout, "text/plain", attractors)
        println()
    end
    (isempty(fig.content) || events(fig).window_open[]) && return
    display(GLMakie.Screen(), fig)
end

Base.show(attractor_set::T) where T <: AttractorSet = println(T)

Base.getindex(attractor::Attractor) = attractor

Base.getindex(attractors::Vector{<:Attractor}) = first(attractors)

end
