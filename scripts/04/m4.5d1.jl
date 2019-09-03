# Estimate polynomial linear regression model with a half-T prior.

using DynamicHMCModels

ProjDir = @__DIR__
cd(ProjDir)

# Import the dataset.

data = DataFrame(CSV.read(joinpath("..", "..", "data", "Howell1.csv"), delim=';'));

# Use only adults and standardize

df = filter(row -> row[:age] >= 18, data);
df[!, :weight] = convert(Vector{Float64}, df[:, :weight]);
df[!, :weight_s] = (df[:, :weight] .- mean(df[:, :weight])) / std(df[:, :weight]);
df[!, :weight_s2] = df[:, :weight_s] .^ 2;


# Define a structure to hold the data: observables, covariates,
# and the degrees of freedom for the prior.

"""
Linear regression model ``y ∼ Xβ + ϵ``, where ``ϵ ∼ N(0, σ²)`` IID.
Flat prior for `β`, half-T for `σ`.
"""
Base.@kwdef mutable struct LinearRegressionModel{Ty <: AbstractVector, Tx <: AbstractMatrix,
Tv <: Real}
    "Observations."
    y::Ty
    "Covariates"
    x::Tx
    "Degrees of freedom for prior."
    v::Tv
end

# Write a function to return a properly dimensioned transformation.

function make_transformation(model::LinearRegressionModel)
  as((β = as(Array, size(model.x, 2)), σ = asℝ₊))
end

N = size(df, 1)
x = hcat(ones(N), hcat(df[:, :weight_s], df[:, :weight_s2]));
model = LinearRegressionModel(;y = df[:, :height], x=x, v=1.0)
  
# Pack parameters *as a single argument*.

function (model::LinearRegressionModel)(θ)
    @unpack y, x, v = model   # extract data
    @unpack β, σ = θ                 # extract parameters
    loglikelihood(Normal(0, σ), y .- x*β) + logpdf(TDist(v), σ)
end

# Evaluate at model function at some initial valuues

println()
model((β = [1.0, 2.0, 3.0], σ = 1.0)) |> display
println()

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

a3d = Array{Float64, 3}(undef, 1000, 4, 1);
for j in 1:1
  for i in 1:1000
    a3d[i, 1:3, j] = values(posterior[i].β)
    a3d[i, 4, j] = values(posterior[i].σ)
  end
end

pnames = ["β[1]", "β[2]", "β[3]", "σ"]
sections =   Dict(
  :parameters => pnames,
)
chns = create_mcmcchains(a3d, pnames, sections, start=1);
chns = set_names(chns, Dict("β[1]" => "α", "β[2]" => "β[1]", "β[3]" => "β[2]"))

stan_result = "
Iterations = 1:1000
Thinning interval = 1
Chains = 1,2,3,4
Samples per chain = 1000

Empirical Posterior Estimates:
           Mean         SD       Naive SE       MCSE      ESS
    a 154.609019750 0.36158389 0.0057171433 0.0071845548 1000
   b1   5.838431778 0.27920926 0.0044146860 0.0048693502 1000
   b2  -0.009985954 0.22897191 0.0036203637 0.0047224478 1000
sigma   5.110136300 0.19096315 0.0030193925 0.0030728192 1000

Quantiles:
          2.5%        25.0%        50.0%       75.0%        97.5%   
    a 153.92392500 154.3567500 154.60700000 154.8502500 155.32100000
   b1   5.27846200   5.6493250   5.83991000   6.0276275   6.39728200
   b2  -0.45954687  -0.1668285  -0.01382935   0.1423620   0.43600905
sigma   4.76114350   4.9816850   5.10326000   5.2300450   5.51500975
";

describe(chns)

# end of m4.5d.jl