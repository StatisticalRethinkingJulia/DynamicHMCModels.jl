using DynamicHMCModels, MCMCChains
using Flux

ProjDir = @__DIR__
cd(ProjDir)

include(joinpath(@__DIR__, "LBA_functions.jl"))

Base.@kwdef struct LBAModel{T}
   data::T
   N::Int
   Nc::Int
end

function make_transformation(model::LBAModel)
    as((v=as(Array,asℝ₊,Nc),A=asℝ₊,k=asℝ₊,tau=asℝ₊))
end

N = 20
data=simulateLBA(;Nd=N,v=[1.0,1.5,2.0],A=.8,k=.2,tau=.4)  
Nc = 3

#dist = LBA(ν=[1.0,1.5,2.0],A=.8,k=.2,τ=.4)
#data = rand(dist,N)

model = LBAModel(; data=data, N=N, Nc=Nc)

function (model::LBAModel)(θ)
    @unpack data=model
    @unpack v,A,k,tau=θ
    d=LBA(ν=v,A=A,k=k,τ=tau)
    minRT = minimum(x->x[2],data)
    logpdf(d,data)+sum(logpdf.(TruncatedNormal(0,3,0,Inf),v)) +
    logpdf(TruncatedNormal(.8,.4,0,Inf),A)+logpdf(TruncatedNormal(.2,.3,0,Inf),k)+
    logpdf(TruncatedNormal(.4,.1,0,minRT),tau)
end

d = [(c,r) for (c,r) in zip(data.choice,data.rt)]

p = LBAModel(d,N,Nc)
p((v=fill(.5,Nc),A=.8,k=.2,tau=.4))

# Use Flux for the gradient.
P = TransformedLogDensity(make_transformation(p), p)
∇P = ADgradient(:Flux, P)

# Sample from the posterior.
results = mcmc_with_warmup(Random.GLOBAL_RNG, ∇P, 1000)
posterior = P.transformation.(results.chain)
