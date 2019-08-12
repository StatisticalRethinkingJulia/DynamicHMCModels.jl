#####
##### IMPORTANT: API is WIP, make sure you use this on DynamicHMC#tp/major-api-rewrite-2.0
#####

using DynamicHMC, LogDensityProblems, TransformVariables, StatsFuns, Distributions,
    Parameters, CSV, DataFrames, Random, StatsBase
using StanSample, DynamicHMCModels
import Flux

ProjDir = rel_path_d("..", "scripts", "10")
cd(ProjDir)

# ### snippet 10.4

data = DataFrame(CSV.read(rel_path("..", "data", "chimpanzees.csv"), delim=';'))

Base.@kwdef struct Chimpanzees
    "Number of actors"
    N_actors::Int
    pulled_left::Vector{Int}
    prosoc_left::Vector{Int}
    condition::Vector{Int}
    actor::Vector{Int}
end

function make_transformation(model::Chimpanzees)
    as((a = as(Vector, model.N_actors), bp = asℝ, bpC = asℝ))
end

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

EBFMI(results.tree_statistics)

NUTS_statistics(results.tree_statistics)
a3d = Array{Float64, 3}(undef, 1000, 9, 1);
for j in 1:1
  for i in 1:1000
    a3d[i, 1, j] = values(posterior[i].bp)
    a3d[i, 2, j] = values(posterior[i].bpC)
    a3d[i, 3:9, j] = values(posterior[i].a)
  end
end

# Create MCMCChains object

parameter_names = ["bp", "bpC"]
pooled_parameter_names = ["a[$i]" for i in 1:7]
sections =   Dict(
  :parameters => parameter_names,
  :pooled => pooled_parameter_names
)
cnames = vcat(parameter_names, pooled_parameter_names)
chns = create_mcmcchains(a3d, cnames, sections, start=1)

# Result rethinking

rethinking = "
Iterations = 1:1000
Thinning interval = 1
Chains = 1,2,3,4
Samples per chain = 1000

Empirical Posterior Estimates:
        Mean        SD       Naive SE       MCSE      ESS
a.1 -0.74503184 0.26613979 0.0042080396 0.0060183398 1000
a.2 10.77955494 5.32538998 0.0842018089 0.1269148045 1000
a.3 -1.04982353 0.28535997 0.0045119373 0.0049074219 1000
a.4 -1.04898135 0.28129307 0.0044476339 0.0056325117 1000
a.5 -0.74390933 0.26949936 0.0042611590 0.0052178124 1000
a.6  0.21599365 0.26307574 0.0041595927 0.0045153523 1000
a.7  1.81090866 0.39318577 0.0062168129 0.0071483527 1000
 bp  0.83979926 0.26284676 0.0041559722 0.0059795826 1000
bpC -0.12913322 0.29935741 0.0047332562 0.0049519863 1000
";

# Describe draws

describe(chns) |> display

# Describe pooled draws

describe(chns, sections=[:pooled])
