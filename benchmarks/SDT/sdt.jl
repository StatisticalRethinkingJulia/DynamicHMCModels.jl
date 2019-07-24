using DynamicHMCModels

Random.seed!(1)

cd(@__DIR__)
include("sdt_functions.jl")
include("simulateSDT.jl")

struct SDTProblem
    hits::Int64
    fas::Int64
    Nd::Int64
end

function (problem::SDTProblem)(θ)
    @unpack hits,fas,Nd=problem   # extract the data
    @unpack d,c=θ
    logpdf(SDT(d,c),[hits,fas,Nd])+logpdf(Normal(0,1/sqrt(2)),d) +
    logpdf(Normal(0,1/sqrt(2)),c)
end

# Define problem with data and inits.

data = simulateSDT(;Nd=100)

p = SDTProblem(data...)
p((d=2.0,c=.0))

# Write a function to return properly dimensioned transformation.
problem_transformation(p::SDTProblem) =
     as((d=asℝ,c=asℝ))
     
# Use Flux for the gradient.
P = TransformedLogDensity(problem_transformation(p), p)
∇P = ADgradient(:ForwardDiff, P);

#import Zygote
#∇P = ADgradient(:Zygote, P);

# FSample from the posterior.
chain, NUTS_tuned = NUTS_init_tune_mcmc(∇P, 4000);

# Undo the transformation to obtain the posterior from the chain.
posterior = TransformVariables.transform.(Ref(problem_transformation(p)),
  get_position.(chain));

chns = nptochain(posterior,NUTS_tuned)
