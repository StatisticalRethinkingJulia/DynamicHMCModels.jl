using DynamicHMCModels

Random.seed!(1)

ProjDir = @__DIR__
cd(ProjDir)

include("simulatePoisson.jl")

struct PoissonProb
   y::Array{Int64,1}
   x::Array{Float64,1}
   idx::Array{Int64,1}
   N::Int64
   Ns::Int64
end

function (problem::PoissonProb)(θ)
   @unpack y, x, idx, N, Ns = problem   # extract the data
   @unpack a0,a1,a0s,a0_sig = θ
   LL = 0.0
   LL += logpdf(Cauchy(0, 1),a0_sig)
   LL += sum(logpdf.(Normal(0,a0_sig),a0s))
   LL += logpdf.(Normal(0, 10),a0)
   LL += logpdf.(Normal(0, 1),a1)
   for i in 1:N
      λ = exp(a0 + a0s[idx[i]] + a1*x[i])
      LL += logpdf(Poisson(λ),y[i])
   end
   return LL
end

y, x, idx, N, Ns = simulatePoisson(;Nd=1,Ns=10,a0=1.0,a1=.5,a0_sig=.3)
p = PoissonProb(y,x,idx,N,Ns)
p((a0=0.0,a1=0.0,a0s=fill(0.0,Ns),a0_sig=.3))

# Write a function to return properly dimensioned transformation.

problem_transformation(p::PoissonProb) =
 as( (a0 = asℝ, a1 = asℝ, a0s = as(Array, Ns), a0_sig = asℝ₊) )
 
# Use Flux for the gradient.

P = TransformedLogDensity(problem_transformation(p), p)
#∇P = LogDensityRejectErrors(ADgradient(:ForwardDiff, P))

import Zygote
∇P = ADgradient(:Zygote, P)

# FSample from the posterior.
chain, NUTS_tuned = NUTS_init_tune_mcmc(∇P, 1000);
# Undo the transformation to obtain the posterior from the chain.
posterior = TransformVariables.transform.(Ref(problem_transformation(p)), get_position.(chain));

chns = nptochain(posterior,NUTS_tuned)
