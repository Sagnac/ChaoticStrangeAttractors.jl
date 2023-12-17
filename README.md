# ChaoticStrangeAttractors.jl

<video src="./videos/aizawa.webm" width="600" height="450" autoplay loop></video>

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
attract!("rossler.webm", attractor, t = 54)
```
