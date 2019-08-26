# # Linear regression

using DynamicHMCModels

ProjDir = @__DIR__
cd(ProjDir)

# Import the dataset.

# ### snippet 5.4

df = DataFrame(CSV.read(joinpath("..", "..", "data", "WaffleDivorce.csv"), delim=';'))

mean_ma = mean(df[!, :Marriage])
df[!, :Marriage_s] = convert(Vector{Float64},
  (df[!, :Marriage]) .- mean_ma)/std(df[!, :Marriage]);

mean_mam = mean(df[!, :MedianAgeMarriage])
df[!, :MedianAgeMarriage_s] = convert(Vector{Float64},
  (df[!, :MedianAgeMarriage]) .- mean_mam)/std(df[!, :MedianAgeMarriage]);

# Model ``y ∼ Xβ + ϵ``, where ``ϵ ∼ N(0, σ²)`` IID. Student on σ

Base.@kwdef mutable struct WaffleDivorce{Ty <: AbstractVector, Tx <: AbstractMatrix}
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

x = hcat(ones(size(df, 1)), df[!, :Marriage_s], df[!, :MedianAgeMarriage_s]);
model = WaffleDivorce(;y=df[!, :Divorce], x=x);

# Make the type callable with the parameters *as a single argument*.

function (model::WaffleDivorce)(θ)
    @unpack y, x = model   # extract the data
    @unpack β, σ = θ            # works on the named tuple too
    ll = 0.0
    ll += logpdf(Normal(10, 10), x[1])
    ll += logpdf(Normal(0, 1), x[2])
    ll += logpdf(Normal(0, 1), x[3])
    ll += logpdf(TDist(1.0), σ)
    ll += loglikelihood(Normal(0, σ), y .- x*β)
    ll
end

println()
model((β = [1.0, 2.0, 3.0], σ = 1.0)) |> display
println()

# Instantiate the model with data and inits.

println()
model((β = [1.0, 2.0, 3.0], σ = 1.0))
println()

# Wrap the problem with a transformation, then use Flux for the gradient.

P = TransformedLogDensity(make_transformation(model), model)
∇P = ADgradient(:Flux, P);

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
          Mean        SD       Naive SE       MCSE      ESS
    a  9.69137275 0.21507432 0.0034006235 0.0038501180 1000
   bA -1.12184710 0.29039965 0.0045916216 0.0053055477 1000
   bM -0.12106472 0.28705400 0.0045387223 0.0051444688 1000
sigma  1.52326545 0.16272599 0.0025729239 0.0034436330 1000

Quantiles:
         2.5%       25.0%      50.0%      75.0%       97.5%   
    a  9.2694878  9.5497650  9.6906850  9.83227750 10.11643500
   bA -1.6852295 -1.3167700 -1.1254650 -0.92889225 -0.53389157
   bM -0.6889247 -0.3151695 -0.1231065  0.07218513  0.45527243
sigma  1.2421182  1.4125950  1.5107700  1.61579000  1.89891925
";

describe(chns)

# end of m4.5d.jl