# # Estimate Binomial draw probabilility

using DynamicHMCModels

# Define a structure to hold the data.

struct BernoulliProblem
    "Total number of draws in the data."
    n::Int
    "Number of draws `==1` in the data"
    s::Vector{Int}
end;

# Make the type callable with the parameters *as a single argument*. 

function (problem::BernoulliProblem)((α, )::NamedTuple{(:α, )})
    @unpack n, s = problem        # extract the data
    loglikelihood(Binomial(n, α), s)
end

# Create the data and complete setting up the problem.

obs = rand(Binomial(9, 2/3), 1)
p = BernoulliProblem(9, obs)
p((α = 0.5, ))

# Write a function to return properly dimensioned transformation.

problem_transformation(p::BernoulliProblem) =
    as((α = as𝕀, ),  )

# Use a flat priors (the default, omitted) for α

P = TransformedLogDensity(problem_transformation(p), p)
∇P = ADgradient(:ForwardDiff, P);

#import Zygote
#∇P = ADgradient(:Zygote, P);

# Sample

chain, NUTS_tuned = NUTS_init_tune_mcmc(∇P, 1000)

# To get the posterior for ``α`` use `get_position` and then transform back.

posterior = TransformVariables.transform.(Ref(problem_transformation(p)), get_position.(chain));

# Extract the parameter.

posterior_α = first.(posterior);

# check the effective sample size

ess_α = effective_sample_size(posterior_α)

# NUTS-specific statistics

NUTS_statistics(chain)
# check the mean

mean(posterior_α)

