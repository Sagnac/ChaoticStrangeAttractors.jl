module ChaoticStrangeAttractors

export attract!, Attractor, cycle_colors, Rossler, Lorenz, Aizawa

using Printf
using GLMakie
using .Iterators: peel

const interval = 0.05

mutable struct State
    position::Scatter{Tuple{Vector{Point{3, Float32}}}}
    segments::Lines{Tuple{Vector{Point{3, Float32}}}}
    axis::Axis3
    colors::Tuple{RGBf, RGBf}
    State() = new()
    State(position, segments, axis, colors) = new(position, segments, axis, colors)
end

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

function unroll!(attractor!::Attractor)
    (; position, segments, axis, colors) = attractor!.state
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

function unroll!(attractors::Vector{<:Attractor})
    for attractor ∈ attractors
        unroll!(attractor)
    end
end

function init!(attractor::Attractor, axis::Axis3)
    (; x, y, z, fig) = attractor
    (; palette, selection) = cycle_colors
    colors = map(i -> palette[i], selection)
    cycle_colors()
    segments = lines!(axis, attractor.points...; color = colors[1])
    position = scatter!(axis, x, y, z; color = colors[2])
    state = State(position, segments, axis, colors)
    attractor.state = state
    return
end

function init!(attractors::Vector{<:Attractor}, axis::Axis3)
    initial, links = peel(attractors)
    init!(initial, axis)
    for attractor ∈ links
        attractor.fig = initial.fig
        init!(attractor, axis)
    end
end

function set!(attractors::Attractors)
    attractor = attractors[]
    (; fig) = attractor
    T = typeof(attractor)
    axis = Axis3(fig[1,1]; title = "$T attractor")
    init!(attractors, axis)
    display(GLMakie.Screen(), fig)
    return fig, T
end

function set!(fig::Figure)
    play = Button(fig[1,2]; label = "\u23ef", fontsize = 16, tellheight = false)
    colsize!(fig.layout, 1, Aspect(1, 1.0))
    return play
end
    
function attract!(attractors::Attractors = Rossler();
                  t::Real = 125, paused::Bool = false)
    fig, = set!(attractors)
    play = set!(fig)
    local t1, t2
    function start_timers()
        t1 = Timer(_ -> unroll!(attractors), 0; interval)
        t2 = Timer(_ -> t ≠ Inf ? stop_timers() : nothing, t)
        paused = false
    end
    function stop_timers()
        close(t1)
        close(t2)
        paused = true
    end
    on(events(fig).window_open) do window_open
        !paused && !window_open && stop_timers()
    end
    on(play.clicks) do _
        paused ? start_timers() : stop_timers()
    end
    paused || start_timers()
    return attractors
end

function attract!(
    file_path  :: String,
    attractors :: Attractors = Aizawa();
    t          :: Real       = 125
)
    fig, T = set!(attractors)
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

# printing vectors will first call 3-arg show and fall back to 2-arg show for output
# if there are line breaks; this allows the figure display logic to fire while at the
# same time printing the more concise format
function Base.show(io::IO, attractor::T) where T <: Attractor
    for name ∈ fieldnames(T)
        name == :x && break
        @printf(io, "%s = %.4f, ", name, getfield(attractor, name))
    end
    @printf(io, "x_0 = %.4f, y_0 = %.4f, z_0 = %.4f", first.(attractor.points)...)
end

function Base.show(io::IO, ::MIME"text/plain", attractor::T) where T <: Attractor
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

Base.getindex(attractor::Attractor) = attractor

Base.getindex(attractors::Vector{<:Attractor}) = first(attractors)

end
