# # Estimate Binomial draw probabilility

using DynamicHMCModels, MCMCChains
import Flux

# Define a structure to hold the data.

Base.@kwdef struct BernoulliProblem
    "Total number of draws in the data."
    n::Int
    "Number of draws ' == 1' "
    obs::Vector{Int}
end;

# Write a function to return properly dimensioned transformation.

make_transformation(model::BernoulliProblem) =
    as((p = as𝕀, ))

# Add data

model = BernoulliProblem(; n = 9, obs = rand(Binomial(9, 2/3), 3))

# Make the type callable with the parameters *as a single argument*. 

function (model::BernoulliProblem)(θ)
    @unpack n, obs = model        # extract the data
    @unpack p = θ
    loglikelihood(Binomial(n, p), obs)
end

# Use a flat priors (the default, omitted) for α

P = TransformedLogDensity(make_transformation(model), model)
∇P = ADgradient(:Flux, P);

# Sample 4 chains

a3d = Array{Float64, 3}(undef, 1000, 1, 4);
for j in 1:4
  global results = mcmc_with_warmup(Random.GLOBAL_RNG, ∇P, 1000)
  posterior = P.transformation.(results.chain)

  for i in 1:1000
    a3d[i, 1, j] = values(posterior[i].p)
  end
end

# Create MCMCChains object

parameter_names = ["p"]
sections =   Dict(
  :parameters => parameter_names,
)
chns = create_mcmcchains(a3d, parameter_names, sections, start=1)
show(chns)

println()
DynamicHMC.Diagnostics.EBFMI(results.tree_statistics) |> display

println()
DynamicHMC.Diagnostics.summarize_tree_statistics(results.tree_statistics)

