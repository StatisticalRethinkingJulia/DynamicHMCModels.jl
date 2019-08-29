# # Heights_2 problem with restricted prior on mu.

using DynamicHMCModels

ProjDir = @__DIR__
cd(ProjDir)

# Import the dataset.

data = DataFrame(CSV.read(joinpath("..", "..", "data", "Howell1.csv"), delim=';'));

# Use only adults and standardize

df = filter(row -> row[:age] >= 18, data);

# Flat `σ`, see below.

Base.@kwdef mutable struct Heights_2{Ty <: AbstractVector}
    "Observations."
    y::Ty
end;

# Write a function to return properly dimensioned transformation.

function make_transformation(model::Heights_2)
    as((σ = asℝ₊, μ  = as(Real, 100, 250)), )
end

model = Heights_2(;y = df[!, :height])
  
# Then make the type callable with the parameters *as a single argument*. Very constraint prior on μ. Flat σ.

function (model::Heights_2)(θ)
    @unpack y = model   # extract the data
    @unpack μ, σ = θ
    loglikelihood(Normal(μ, σ), y) + logpdf(Normal(178, 0.1), μ) + 
    logpdf(Uniform(0, 50), σ)
end;

# Wrap the problem with a transformation, then use Flux for the gradient.

P = TransformedLogDensity(make_transformation(model), model)
∇P = ADgradient(:ForwardDiff, P);

# Tune and sample.

results = mcmc_with_warmup(Random.GLOBAL_RNG, ∇P, 1000)
posterior = P.transformation.(results.chain)

println()
DynamicHMC.Diagnostics.EBFMI(results.tree_statistics) |> display
println()

DynamicHMC.Diagnostics.summarize_tree_statistics(results.tree_statistics) |> display
println()

a3d = Array{Float64, 3}(undef, 1000, 2, 1);
for j in 1:1
  for i in 1:1000
    a3d[i, 1, j] = values(posterior[i].μ)
    a3d[i, 2, j] = values(posterior[i].σ)
  end
end

pnames = ["μ", "σ"]
sections =   Dict(
  :parameters => pnames,
)
chns = create_mcmcchains(a3d, pnames, sections, start=1);

# cmdstan result

stan_result = "
Iterations = 1:1000
Thinning interval = 1
Chains = 1,2,3,4
Samples per chain = 1000

Empirical Posterior Estimates:
         Mean         SD       Naive SE       MCSE      ESS
sigma  24.604616 0.946911707 0.0149719887 0.0162406632 1000
   mu 177.864069 0.102284043 0.0016172527 0.0013514459 1000

Quantiles:
         2.5%       25.0%     50.0%     75.0%     97.5%  
sigma  22.826377  23.942275  24.56935  25.2294  26.528368
   mu 177.665000 177.797000 177.86400 177.9310 178.066000
";

describe(chns)

# end of m4.2d.jl