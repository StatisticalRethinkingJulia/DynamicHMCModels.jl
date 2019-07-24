using DynamicHMCModels

struct BernoulliProblem
    "Total number of draws in the data."
    n::Int
    "Number of draws `==1` in the data"
    s::Vector{Int}
end;

function (problem::BernoulliProblem)((α, )::NamedTuple{(:α, )})
    @unpack n, s = problem        # extract the data
    loglikelihood(Binomial(n, α), s)
end

obs = rand(Binomial(9, 2/3), 1)
p = BernoulliProblem(9, obs)
p((α = 0.5, ))

problem_transformation(p::BernoulliProblem) =
    as((α = as𝕀, ),  )

P = TransformedLogDensity(problem_transformation(p), p)
∇P = ADgradient(:ForwardDiff, P);

#import Zygote
#∇P = ADgradient(:Zygote, P);

chain, NUTS_tuned = NUTS_init_tune_mcmc(∇P, 1000)

posterior = TransformVariables.transform.(Ref(problem_transformation(p)), get_position.(chain));

posterior_α = first.(posterior);

ess_α = effective_sample_size(posterior_α)

NUTS_statistics(chain)

mean(posterior_α)

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

