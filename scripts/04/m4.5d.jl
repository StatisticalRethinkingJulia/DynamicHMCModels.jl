using DynamicHMCModels
using BenchmarkTools
using RegressionAndOtherStories

ProjDir = @__DIR__

data = CSV.read(joinpath(ProjDir, "..", "..", "data", "Howell1.csv"), DataFrame)

begin
  df = filter(row -> row[:age] >= 18, data)
  df[!, :weight] = convert(Vector{Float64}, df[:, :weight])
  df[!, :weight_s] = (df[:, :weight] .- mean(df[:, :weight])) / std(df[:, :weight])
  df[!, :weight_s2] = df[:, :weight_s] .^ 2
  df
end

# LR model ``y ∼ xβ + ϵ``, where ``ϵ ∼ N(0, σ²)`` IID.

struct Heights2{Ty <: AbstractVector, Tx <: AbstractMatrix}
    "Observations."
    y::Ty
    "Covariates"
    x::Tx
end

# Write a function to return a properly dimensioned transformation.

function make_transformation(model::Heights2)
  as((β = as(Array, size(model.x, 2)), σ = asℝ₊))
end

# Pack the parameters in a single argument θ.

function (problem::Heights2)(θ)
    @unpack y, x = problem   # extract the data
    @unpack β, σ = θ            # works on the named tuple too
    ll = 0.0
    ll += logpdf(Normal(178, 100), x[1]) # a = x[1]
    ll += logpdf(Normal(0, 10), x[2]) # b1 = x[2]
    ll += logpdf(Normal(0, 10), x[3]) # b2 = x[3]
    ll += logpdf(TDist(1.0), σ)
    ll += loglikelihood(Normal(0, σ), y .- x*β)
    ll
end

  N = size(df, 1)
  x = hcat(ones(N), hcat(df[:, :weight_s], df[:, :weight_s2]));
  p = Heights2(df[:, :height], x)

p((β = [1.0, 2.0, 3.0], σ = 1.0)) |> display

t = make_transformation(p)

# Wrap the problem with a transformation, then use Flux for the gradient.

P = TransformedLogDensity(t, p)

∇P = ADgradient(:ForwardDiff, P);

# Tune and sample.

results = map(_ -> mcmc_with_warmup(Random.GLOBAL_RNG, ∇P, 1000), 1:4)

posterior = TransformVariables.transform.(t, eachcol(pool_posterior_matrices(results)))

posterios_σ = round(mean(last, posterior); digits=2)

posterios_β = round.(mean(first, posterior); digits=2)
posterios_β |> display

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

ess, R̂ = ess_rhat(stack_posterior_matrices(results))

summarize_tree_statistics(mapreduce(x -> x.tree_statistics, vcat, results))
