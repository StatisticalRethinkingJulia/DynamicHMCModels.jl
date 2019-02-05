module DynamicHMCModels

using Reexport 

@reexport using SR, CSV
@reexport using DynamicHMC, TransformVariables, LogDensityProblems
@reexport using MCMCDiagnostics
@reexport using Parameters, ForwardDiff

using DataStructures
import SR: scriptentry

const src_path_d = @__DIR__

"""

# rel_path_d

Relative path using the DynamicHMCModels src/ directory. 

### Example to get access to the data subdirectory
```julia
rel_path_d("..", "data")
```
"""
rel_path_d(parts...) = normpath(joinpath(src_path_d, parts...))

include("scriptdict_d.jl")
include("generate_d.jl")

export
  rel_path_d,
  generate_d,
  scriptentry

end # module
