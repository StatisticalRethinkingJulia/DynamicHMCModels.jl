# # Linear regression

using DynamicHMCModels

ProjDir = @__DIR__
cd(ProjDir)

# Import the dataset.

# ### snippet 5.1

df = DataFrame(CSV.read(joinpath("..", "..", "data", "WaffleDivorce.csv"), delim=';'))
mean_ma = mean(df[!, :MedianAgeMarriage])
df[!, :MedianAgeMarriage_s] = convert(Vector{Float64},
  (df[!, :MedianAgeMarriage]) .- mean_ma)/std(df[!, :MedianAgeMarriage]);

# Model ``y ∼ Normal(y - Xβ, σ)``. Flat prior `β`, half-T for `σ`.

Base.@kwdef mutable struct WaffleDivorce{Ty <: AbstractVector, 
  Tx <: AbstractMatrix}
    "Observations."
    y::Ty
    "Covariates"
    x::Tx
end

# Write a function to return a properly dimensioned transformation.

function make_transformation(model::WaffleDivorce)
  as((β = as(Array, size(model.x, 2)), σ = asℝ₊))
end

# Instantiate the model with data and inits.

x = hcat(ones(size(df, 1)), df[!, :MedianAgeMarriage_s]);
model = WaffleDivorce(;y=df[!, :Divorce], x=x);

# Make tmodel callable with the parameters *as a single argument*.

function (model::WaffleDivorce)(θ)
    @unpack y, x = model   # extract the data
    @unpack β, σ = θ            # works on the named tuple too
    ll = 0.0
    ll += logpdf(Normal(10, 10), x[1]) # alpha
    ll += logpdf(Normal(0, 1), x[2]) # beta
    ll += logpdf(TDist(1.0), σ)
    ll += loglikelihood(Normal(0, σ), y .- x*β)
    ll
end

println()
model((β = [1.0, 2.0], σ = 1.0)) |> display
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

a3d = Array{Float64, 3}(undef, 1000, 3, 1);
for j in 1:1
  for i in 1:1000
    a3d[i, 1:2, j] = values(posterior[i].β)
    a3d[i, 3, j] = values(posterior[i].σ)
  end
end

pnames = ["β[1]", "β[2]", "σ"]
sections =   Dict(
  :parameters => pnames,
)
chns = create_mcmcchains(a3d, pnames, sections, start=1);
chns = set_names(chns, Dict("β[1]" => "α", "β[2]" => "β"))

stan_result = "
Iterations = 1:1000
Thinning interval = 1
Chains = 1,2,3,4
Samples per chain = 1000

Empirical Posterior Estimates:
         Mean        SD       Naive SE       MCSE      ESS
    a  9.6882466 0.22179190 0.0035068378 0.0031243061 1000
   bA -1.0361742 0.21650514 0.0034232469 0.0034433245 1000
sigma  1.5180337 0.15992781 0.0025286807 0.0026279593 1000

Quantiles:
         2.5%      25.0%     50.0%      75.0%       97.5%   
    a  9.253141  9.5393175  9.689585  9.84221500 10.11121000
   bA -1.454571 -1.1821025 -1.033065 -0.89366925 -0.61711705
sigma  1.241496  1.4079225  1.504790  1.61630750  1.86642750
";

# Describe chains

describe(chns)

# end of m4.5d.jl