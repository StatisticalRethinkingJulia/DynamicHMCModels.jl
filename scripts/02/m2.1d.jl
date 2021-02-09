# # Estimate Binomial draw probabilility

using DynamicHMCModels

Random.seed!(1356779)

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
∇P = ADgradient(:ForwardDiff, P);

# Sample chain

results = mcmc_with_warmup(Random.GLOBAL_RNG, ∇P, 1000;
  reporter = NoProgressReport()
)

posterior = P.transformation.(results.chain)

# Create Particles NamedTuple object

println()
p = as_particles(posterior)
p |> display

println()
DynamicHMC.Diagnostics.EBFMI(results.tree_statistics) |> display

println()
DynamicHMC.Diagnostics.summarize_tree_statistics(results.tree_statistics) |> display
