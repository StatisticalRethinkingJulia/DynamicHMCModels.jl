using DynamicHMCModels, MCMCChains, Random

#Random.seed!(1233)

ProjDir = @__DIR__
cd(ProjDir)

include(joinpath(@__DIR__, "LBA_functions.jl"))

Base.@kwdef struct LBAModel{T}
   data::T
   N::Int
   Nc::Int
end

function make_transformation(model::LBAModel)
    as((v=as(Array,asℝ₊,Nc), A=asℝ₊, k=asℝ₊, tau=asℝ₊))
end

N = 10
v = [1.0, 1.5]
Nc = length(v)
data=simulateLBA(;Nd=N,v=v,A=.8,k=.2,tau=.4)  

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
∇P = ADgradient(:ForwardDiff, P)

# Sample from the posterior.
results = mcmc_with_warmup(Random.GLOBAL_RNG, ∇P, 1000;
  warmup_stages = default_warmup_stages(local_optimization=nothing),
  reporter = NoProgressReport()
  )
posterior = P.transformation.(results.chain)

@show DynamicHMC.Diagnostics.EBFMI(results.tree_statistics)
println()
@show DynamicHMC.Diagnostics.summarize_tree_statistics(results.tree_statistics)
println()

parameter_names = ["v[1]", "v[2]", "A", "k", "tau"]

# Create a3d
a3d = Array{Float64, 3}(undef, 1000, 5, 1);
for j in 1:1
  for i in 1:1000
    a3d[i, 1:2, j] = values(posterior[i].v)
    a3d[i, 3, j] = values(posterior[i].A)
    a3d[i, 4, j] = values(posterior[i].k)
    a3d[i, 5, j] = values(posterior[i].tau)
  end
end

chns = MCMCChains.Chains(a3d,
  vcat(parameter_names),
  Dict(
    :parameters => parameter_names
  )
)

describe(chns)
