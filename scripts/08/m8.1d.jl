# Load Julia packages (libraries) needed  for the snippets in chapter 0

using DynamicHMCModels

ProjDir = @__DIR__
cd(ProjDir)

# Read in data

delim = ';'
df = CSV.read(joinpath("..", "..", "data", "rugged.csv"), DataFrame; delim)
df = filter(row -> !(ismissing(row[:rgdppc_2000])), df)
df.log_gdp = log.(df.rgdppc_2000)
df.cont_africa = Array{Float64}(convert(Array{Int}, df.cont_africa))

Base.@kwdef mutable struct RuggedModel{Ty <: AbstractVector,
  Tx <: AbstractMatrix}
    "Observations."
    y::Ty
    "Covariates"
    x::Tx
end

# Write a function to return properly dimensioned transformation.

function make_transformation(model::RuggedModel)
  as((β = as(Array, size(model.x, 2)), σ = asℝ₊))
end
  
# Instantiate the model with data and inits.

x = hcat(ones(size(df, 1)), df[:, :rugged], df[:, :cont_africa],
  df[:, :rugged] .* df[:, :cont_africa]);
model = RuggedModel(;y=df[:, :log_gdp], x=x)

# Model callable with *a single argument*.

function (problem::RuggedModel)(θ)
    @unpack y, x = problem   # extract the data
    @unpack β, σ = θ            # works on the named tuple too
    ll = 0.0
    ll += logpdf(Normal(0, 100), x[1])
    ll += logpdf(Normal(0, 10), x[2])
    ll += logpdf(Normal(0, 10), x[3])
    ll += logpdf(Normal(0, 10), x[4])
    ll += logpdf(TDist(1.0), σ)
    ll += loglikelihood(Normal(0, σ), y .- x*β)
    ll
end

println()
model((β = [1.0, 2.0, 1.0, 2.0], σ = 1.0))
println()

# Wrap the problem with a transformation, then use Flux for the gradient.

P = TransformedLogDensity(make_transformation(model), model)
∇P = ADgradient(:ForwardDiff, P);

# Tune and sample.

results = mcmc_with_warmup(Random.GLOBAL_RNG, ∇P, 1000)
posterior = P.transformation.(results.chain)

p = as_particles(posterior)
display(p)

# Result rethinking

rethinking = "
       mean   sd  5.5% 94.5% n_eff Rhat
a      9.22 0.14  9.00  9.46   282    1
bR    -0.21 0.08 -0.33 -0.08   275    1
bA    -1.94 0.24 -2.33 -1.59   268    1
bAR    0.40 0.14  0.18  0.62   271    1
sigma  0.96 0.05  0.87  1.04   339    1
"

# End of `08/m8.1s.jl`
