import Base: show, display, getindex, iterate

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

function show(io::IO, attractor::Attractor)
    f = get(io, :typeinfo, false) isa Type ? show_params : recap
    f(io, attractor)
end

function display(attractor_set::T) where T <: AttractorSet
    (; attractor, fig, state) = attractor_set
    if state.paused[]
        println(T, " attractor field:")
        show(stdout, "text/plain", attractor)
        println()
    end
    (isempty(fig.content) || events(fig).window_open[]) && return
    display(GLMakie.Screen(), fig)
end

show(io::IO, ::T) where T <: AttractorSet = println(io, T)

getindex(attractor::Attractor) = attractor

getindex(attractors::Vector{<:Attractor}) = first(attractors)

getindex(set::AttractorSet, i::Int) = set.attractor[i]

getindex(set::AttractorSet) = set.attractor[1]

iterate(attractor::Attractor, i::Int = 1) = (i > 1 ? nothing : (attractor, 2))

function iterate(attractors::AttractorSet, i::Int = 1)
    (; attractor) = attractors
    i > length(attractor) ? nothing : (attractor[i], i + 1)
end
