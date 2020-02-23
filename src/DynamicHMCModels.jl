module DynamicHMCModels

using Reexport, Requires

@reexport using DynamicHMC, LogDensityProblems, TransformVariables
@reexport using Distributions, Random, Statistics
@reexport using Parameters, CSV, DataFrames
@reexport using MonteCarloMeasurements

function __init__()
  @require MCMCChains="c7f686f2-ff18-58e9-bc7b-31028e88f75d" include("require/chains.jl")
end

include("particles.jl")

end # module