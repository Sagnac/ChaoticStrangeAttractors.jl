# ChaoticStrangeAttractors.jl

![aizawa.gif](images/aizawa.gif)

## Installation

```julia
using Pkg
Pkg.add(url = "https://github.com/Sagnac/ChaoticStrangeAttractors.jl")
```

## Usage

```julia
using ChaoticStrangeAttractors
attractor = Rossler(a = 0.2, b = 0.2, c = 5.7, x = 7, y = 0, z = 0)
attract!(attractor, t = 200)

# encoding example
attract!("rossler.mp4", attractor, t = 54)

# run multiple simultaneous paths for the same attractor type
attractors = [Lorenz(; x) for x ∈ 6:8]
attract!(attractors)
```
