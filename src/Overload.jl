import Base: show, display, getindex, iterate, eltype

function recap(io::IO, attractor::T) where T <: Attractor
    (; fig) = attractor
    print(io, T, " attractor:")
    for name ∈ fieldnames(T)
        name == :dt && break
        if name == :x
            @printf(io, "\n\nx_0 = %.4f\ny_0 = %.4f\nz_0 = %.4f\nΔt = %.4g\n",
                first(attractor.points)..., attractor.dt)
        end
        @printf(io, "\n%s = %.4f", name, getfield(attractor, name))
    end
    (isempty(fig.content) || events(fig).window_open[]) && return
    display(fig)
end

function show_params(io::IO, attractor::T) where T <: Attractor
    for name ∈ fieldnames(T)
        name == :x && break
        @printf(io, "%s = %.4f, ", name, getfield(attractor, name))
    end
    @printf(io, "x_0 = %.4f, y_0 = %.4f, z_0 = %.4f", first(attractor.points)...)
end

function show(io::IO, ::MIME"text/plain", attractor::Attractor)
    f = haskey(io, :typeinfo) ? show_params : recap
    f(io, attractor)
    return
end

function display(attractors::Vector{<:Attractor})
    attractor = attractors[]
    (; fig, state) = attractor
    if state.paused[]
        show(stdout, "text/plain", attractors)
        println()
    end
    (isempty(fig.content) || events(fig).window_open[]) && return
    display(fig)
end

getindex(attractor::Attractor) = attractor

getindex(attractors::Vector{<:Attractor}) = first(attractors)

iterate(attractor::Attractor, i::Int = 1) = (i > 1 ? nothing : (attractor, 2))

eltype(::T) where {T <: Attractor} = T
