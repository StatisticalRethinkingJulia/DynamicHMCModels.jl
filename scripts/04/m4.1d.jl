# # Heights_1 problem

# We estimate simple linear regression model with a half-T prior.

using DynamicHMCModels

ProjDir = @__DIR__
cd(ProjDir)

# Import the dataset.

data = DataFrame(CSV.read(joinpath("..", "..", "data", "Howell1.csv"), delim=';'));

# Use only adults and standardize

df = filter(row -> row[:age] >= 18, data);

# Half-T for `σ`, see below.

Base.@kwdef mutable struct Heights_1{Ty <: AbstractVector, Tν <: Real}
    "Observations."
    y::Ty
    "Degrees of freedom for prior on sigma."
    v::Tν
end;

# Write a function to return properly dimensioned transformation.

function make_transformation(model::Heights_1)
    as((σ = asℝ₊, μ  = as(Real, 100, 250)), )
end

model = Heights_1(;y = df[!, :height], v=1.0)
  
# Then make the type callable with the parameters *as a single argument*.

function (model::Heights_1)(θ)
    @unpack y, v = model   # extract the data
    @unpack μ, σ = θ
    loglikelihood(Normal(μ, σ), y) + logpdf(TDist(v), σ)
end;

# Wrap the problem with a transformation, then use Flux for the gradient.

P = TransformedLogDensity(make_transformation(model), model)
∇P = ADgradient(:ForwardDiff, P);

# Tune and sample.

results = mcmc_with_warmup(Random.GLOBAL_RNG, ∇P, 1000)
posterior = P.transformation.(results.chain)

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

# Stan.jl results

cmdstan_result = "
Iterations = 1:1000
Thinning interval = 1
Chains = 1,2,3,4
Samples per chain = 1000

Empirical Posterior Estimates:
          Mean        SD       Naive SE      MCSE      ESS
sigma   7.7641872 0.29928194 0.004732063 0.0055677898 1000
   mu 154.6055177 0.41989355 0.006639100 0.0085038356 1000

Quantiles:
         2.5%      25.0%       50.0%      75.0%       97.5%  
sigma   7.21853   7.5560625   7.751355   7.9566775   8.410391
   mu 153.77992 154.3157500 154.602000 154.8820000 155.431000
";

describe(chns)

# end of m4.1d.jl