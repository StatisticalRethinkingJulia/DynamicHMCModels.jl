using DynamicHMCModels

Random.seed!(1)

cd(@__DIR__)
include("simulateLR.jl")

 struct RegressionProb
    x::Array{Float64,2}
    y::Array{Float64,1}
    Nd::Int64
    Nc::Int64
end

function (problem::RegressionProb)(θ)
    @unpack x,y,Nd,Nc = problem   # extract the data
    @unpack B0,B,sigma = θ
    μ = B0 .+x*B
    sum(logpdf.(Normal.(μ,sigma),y)) + logpdf(Normal(0,10),B0) +
    loglikelihood(Normal(0,10),B) + logpdf(Truncated(Cauchy(0,5),0,Inf),sigma)
end

# Define problem with data and inits.

x, y, Nd, Nc = simulateLR()
p = RegressionProb(x, y, Nd, Nc)
p((B0 = 0.0, B = fill(0.0, Nc), sigma = 1.0))

# Write a function to return properly dimensioned transformation.

problem_transformation(p::RegressionProb) =
    as((B0=asℝ, B=as(Array, asℝ, Nc), sigma = asℝ₊))
    
# Use Flux for the gradient.

P = TransformedLogDensity(problem_transformation(p), p)
∇P = ADgradient(:ForwardDiff, P)

#import Zygote
#∇P = ADgradient(:Zygote, P)

# Sample from the posterior.

chain, NUTS_tuned = NUTS_init_tune_mcmc(∇P, 4000);

# Undo the transformation to obtain the posterior from the chain.

posterior = TransformVariables.transform.(Ref(problem_transformation(p)), get_position.(chain));

chns = nptochain(posterior,NUTS_tuned)
