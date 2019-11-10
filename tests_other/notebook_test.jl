using DynamicHMCModels
#=
using LinearAlgebra
using StaticArrays
using TransformVariables
using LogDensityProblems
using DynamicHMC
using Parameters
using Random
using MCMCChains
=#

function LogLikelihoodMin(ω,dyDep)
    
 dt = 0.1
 cD = [0 -1im ; 1im 0]
 H = (ω/2.) * cD
 rho=[0.05 0 ; 0 0.95]
 M = I - ((cD'*cD)/2) * dt + (cD * dyDep) - 1im * H * dt   
 newRho = M * rho * M'
 lklhood = real(tr(newRho))- (ω* dt/2)^2 
 return log(lklhood)

end

struct Experiment
      dyDep::Float64
end

function (problem::Experiment)((ω,)::NamedTuple{(:ω,)})
      @unpack dyDep  = problem        # extract the data
      LogLikelihoodMin(ω,dyDep)
end

dyDepObs=0.690691
p1 = Experiment(dyDepObs)

println(p1((ω=.4,)))

trans_single = as((ω=as(Real, 2, 4),))
P1 = TransformedLogDensity(trans_single, p1)
∇P1 = ADgradient(:ForwardDiff, P1)

# Sample 4 chains

a3d = Array{Float64, 3}(undef, 1000, 1, 4);
for j in 1:4
  global results = mcmc_with_warmup(Random.GLOBAL_RNG, ∇P1, 1000;
    reporter = NoProgressReport())
  global posterior = P1.transformation.(results.chain)

  for i in 1:1000
    a3d[i, 1, j] = values(posterior[i].ω)
  end
end

# Create MCMCChains object

parameter_names = ["ω"]
sections =   Dict(
  :parameters => parameter_names,
)
chns = create_mcmcchains(a3d, parameter_names, sections, start=1)
show(chns)

println()
DynamicHMC.Diagnostics.EBFMI(results.tree_statistics) |> display

println()
DynamicHMC.Diagnostics.summarize_tree_statistics(results.tree_statistics)
