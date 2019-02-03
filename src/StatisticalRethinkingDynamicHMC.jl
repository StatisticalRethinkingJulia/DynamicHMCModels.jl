module StatisticalRethinkingDynamicHMCDynamicHMC

using Reexport 

@reexport using StatisticalRethinkingDynamicHMC
@reexport using DynamicHMC, TransformVariables, LogDensityProblems
@reexport using MCMCDiagnostics
@reexport using Parameters, ForwardDiff

using DataStructures

const src_path = @__DIR__

"""

# rel_path

Relative path using the StatisticalRethinkingDynamicHMC src/ directory. Copied from
[DynamicHMCExamples.jl](https://github.com/tpapp/DynamicHMCExamples.jl)

### Example to get access to the data subdirectory
```julia
rel_path_d("..", "data")
```
"""
rel_path_d(parts...) = normpath(joinpath(src_path, parts...))

include("scriptdict_d.jl")
include("generate_d.jl")

export
  rel_path_d,
  generate_d

end # module
