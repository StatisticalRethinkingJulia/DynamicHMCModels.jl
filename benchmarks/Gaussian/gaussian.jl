using DynamicHMCModels

Random.seed!(1)

cd(@__DIR__)
include("simulateGaussian.jl")

struct GaussianProb{TY <: AbstractVector}
   "Observations."
   y::TY
end

function (problem::GaussianProb)(θ)
   @unpack y = problem   # extract the data
   @unpack mu, sigma = θ
   loglikelihood(Normal(mu, sigma), y) + logpdf(Normal(0,1), mu) +
   logpdf(Truncated(Cauchy(0,5),0,Inf), sigma)
end

# Define problem with data and inits.
function sampleDHMC(obs,N,nsamples)
 p = GaussianProb(obs);
 p((mu = 0.0, sigma = 1.0))

 # Write a function to return properly dimensioned transformation.

 problem_transformation(p::GaussianProb) =
     as((mu  = as(Real, -25, 25), sigma = asℝ₊), )
     
 # Use Flux for the gradient.
 P = TransformedLogDensity(problem_transformation(p), p)
 
 ∇P = ADgradient(:ForwardDiff, P)
 
 #import Zygote
 #∇P = ADgradient(:Zygote, P)
 
 # Sample from the posterior.
 chain, NUTS_tuned = NUTS_init_tune_mcmc(∇P, nsamples,report=ReportSilent());
 
 # Undo the transformation to obtain the posterior from the chain.
 posterior = TransformVariables.transform.(Ref(problem_transformation(p)),
   get_position.(chain));
 
 chns = nptochain(posterior,NUTS_tuned)
 return chns
end

data = GaussianGen(;Nd=100)

chns = sampleDHMC(data...,2000)
