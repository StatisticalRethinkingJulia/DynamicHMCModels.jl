module DynamicHMCModels

using Reexport 

@reexport using StatisticalRethinking, CSV
@reexport using DynamicHMC, TransformVariables, LogDensityProblems
@reexport using MCMCDiagnostics, LinearAlgebra
@reexport using Parameters, ForwardDiff

using DataStructures

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
include("chains.jl")

export
  rel_path_d,
  script_dict_d,
  generate_d,
  create_a3d,
  insert_chain!,
  create_mcmcchains

end # module
