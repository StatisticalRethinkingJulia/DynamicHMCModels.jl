# Estimate Binomial draw probabilility

using DynamicHMCModels
using Test

# StatisticalRethinking model `m2.1d`"

Random.seed!(1356779)

struct BernoulliProblem
    "Total number of draws in the data."
    n::Int
    "Observations"
    obs::Vector{Int}
end

# Add data


# Make the type callable with the parameters *as a single argument*. 

function (problem::BernoulliProblem)(θ)
    @unpack n, obs = problem        # extract the data
    @unpack p = θ
    loglikelihood(Binomial(n, p), obs)
end

p = BernoulliProblem(9, rand(Binomial(9, 2/3), 3))

p((p = 0.5,))

t = as((p = as𝕀,))

# Use a flat priors (the default, omitted) for α

P = TransformedLogDensity(t, p)

∇P = ADgradient(:ForwardDiff, P);

results = [mcmc_with_warmup(Random.GLOBAL_RNG, ∇P, 1000; reporter = NoProgressReport()) for _ in 1:4]

posterior = TransformVariables.transform.(t, eachcol(pool_posterior_matrices(results)))

posterior_p = first.(posterior)

@test mean(posterior_p) ≈ 0.69 atol=0.1

ess, R̂ = ess_rhat(stack_posterior_matrices(results))

summarize_tree_statistics(results[1].tree_statistics)
