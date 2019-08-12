#####
##### IMPORTANT: API is WIP, make sure you use this on DynamicHMC#tp/major-api-rewrite-2.0
#####

using DynamicHMC, LogDensityProblems, TransformVariables, StatsFuns, Distributions,
    Parameters, CSV, DataFrames, Random, StatsBase
#using StanDump, StanRun, StanSamples, PGFPlotsX
using StanSample
import Flux

ProjDir = @__DIR__

data = DataFrame(CSV.File(ProjDir*"/chimpanzees.csv"; delim = ','))

Base.@kwdef struct Chimpanzees
    N_actors::Int
    pulled_left::Vector{Int}
    prosoc_left::Vector{Int}
    condition::Vector{Int}
    actor::Vector{Int}
end

function make_transformation(model::Chimpanzees)
    as((a = as(Vector, model.N_actors), bp = asℝ, bpC = asℝ))
end

stan_data = (N = length(data.pulled_left), P = data.prosoc_left, C = data.condition,
             L = data.pulled_left, N_chimps = maximum(data.actor), chimp = data.actor)

#=
stan_model = StanModel(joinpath(pwd(), "chimpanzees.stan"))
# just one chain from Stan
stan_chain = first(stan_sample(stan_model, stan_data, 1))
stan_samples = read_samples(first(stan_chain))
=#
             
model = Chimpanzees(; N_actors = maximum(data.actor), pulled_left = data.pulled_left,
                    prosoc_left = data.prosoc_left, condition = data.condition,
                    actor = data.actor)

function (model::Chimpanzees)(θ)
    @unpack a, bp, bpC = θ
    @unpack pulled_left, prosoc_left, condition, actor = model
    ℓ_likelihood = mapreduce(+, actor, condition, prosoc_left,
                             pulled_left) do actor, condition, prosoc_left, pulled_left
                                 p = logistic(a[actor] + (bp + bpC * condition) * prosoc_left)
                                 logpdf(Bernoulli(p), pulled_left)
                             end
    P = Normal(0, 10)
    ℓ_prior = logpdf(P, bpC) + logpdf(P, bp) + sum(a -> logpdf(P, a), a)
    ℓ_prior + ℓ_likelihood
end

P = TransformedLogDensity(make_transformation(model), model)
∇P = ADgradient(:Flux, P)
results = mcmc_with_warmup(Random.GLOBAL_RNG, ∇P, 1000)
posterior = P.transformation.(results.chain)

#=
function comparison_plot(xlabel, dhmc_values, stan_values)
    @pgf Axis({ xlabel = xlabel, ylabel = "ecdf", legend_pos = "south east" },
              Plot({ no_marks, red }, Table(ecdf(dhmc_values))),
              LegendEntry("DynamicHMC"),
              Plot({ no_marks, blue }, Table(ecdf(stan_values))),
              LegendEntry("Stan"))
end

###
### plots will show up interactively
###

comparison_plot("bp", getfield.(posterior, :bp), stan_samples.bp)
comparison_plot("bpC", getfield.(posterior, :bpC), stan_samples.bpc)
p7 = [comparison_plot("a[$(i)]", getindex.(getfield.(posterior, :a), Ref(i)),
                      stan_samples.a_chimp[i, :]) for i in 1:7]

p7[1]
p7[2]
p7[3]
p7[4]
p7[5]
p7[6]
p7[7]
=#

NUTS_statistics(results.tree_statistics)

EBFMI(results.tree_statistics)