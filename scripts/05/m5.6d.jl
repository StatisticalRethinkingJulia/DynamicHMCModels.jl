# Load Julia packages (libraries) needed  for the snippets in chapter 0

using DynamicHMCModels

# CmdStan uses a tmp directory to store the output of cmdstan

ProjDir = @__DIR__
cd(ProjDir)

# Read the milk data

df = DataFrame(CSV.read(joinpath("..", "..", "data", "milk.csv"), delim=';'))
df = filter(row -> !(row[:neocortex_perc] == "NA"), df)
#df[!, :kcal_per_g] = convert(Vector{Float64}, df[!, :kcal_per_g])
df[!, :log_mass] = log.(convert(Vector{Float64}, df[!, :mass]))

# Define the model struct

Base.@kwdef mutable struct MilkModel{Ty <: AbstractVector, Tx <: AbstractMatrix}
    "Observations."
    y::Ty
    "Covariates"
    x::Tx
end

# Write a function to return properly dimensioned transformation.

function make_transformation(model::MilkModel)
  as((β = as(Array, size(model.x, 2)), σ = asℝ₊))
end
  
# Instantiate the model with data and inits.

x = hcat(ones(size(df, 1)), df[!, :log_mass]);
model = MilkModel(;y=df[!, :kcal_per_g], x=x)

# Make the type callable with the parameters *as a single argument*.

function (model::MilkModel)(θ)
    @unpack y, x, = model   # extract the data
    @unpack β, σ = θ            # works on the named tuple too
    ll = 0.0
    ll += logpdf(Normal(0, 100), x[1])
    ll += logpdf(Normal(0, 1), x[2])
    ll += logpdf(TDist(1.0), σ)
    ll += loglikelihood(Normal(0, σ), y .- x*β)
    ll
end

println()
model((β = [1.0, 2.0], σ = 1.0))
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
          Mean         SD        Naive SE       MCSE      ESS
    a  0.70472876 0.057040655 0.00090189195 0.0011398893 1000
   bm -0.03150330 0.023642759 0.00037382484 0.0004712342 1000
sigma  0.18378372 0.039212805 0.00062000888 0.0011395979 1000

Quantiles:
          2.5%       25.0%       50.0%        75.0%       97.5%  
    a  0.59112968  0.66848775  0.70444950  0.741410500 0.81915225
   bm -0.07729257 -0.04708425 -0.03104865 -0.015942925 0.01424901
sigma  0.12638780  0.15605950  0.17800600  0.204319250 0.27993590
";

describe(chns)

# End of `05/5.6d.jl`
