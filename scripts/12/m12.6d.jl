using DynamicHMCModels

ProjDir = @__DIR__

df = DataFrame(CSV.read(joinpath(ProjDir, "..", "..", "data",  "Kline.csv"), delim=';'))

# New col logpop, set log() for population data
df[!, :logpop] = map((x) -> log(x), df[!, :population]);
df[!, :society] = 1:10;

Base.@kwdef mutable struct KlineModel{Ty <: AbstractVector,
  Tx <: AbstractMatrix, Ts <: AbstractVector}
    "Observations (total_tools)."
    y::Ty
    "Covariates (logpop)"
    x::Tx
    "Society"
    s::Ts
    "Number of observations (10)"
    N::Int
    "Number of societies (also 10)"
    N_societies::Int
end

function make_transformation(model::KlineModel)
    as( (β = as(Array, size(model.x, 2)), α = as(Array, model.N_societies), σ = asℝ₊) )
end

# Instantiate the model with data and inits.

N = size(df, 1)
N_societies = length(unique(df[!, :society]))
x = hcat(ones(Int64, N), df[!, :logpop]);
s = df[!, :society]
y = df[!, :total_tools]
model = KlineModel(; y=y, x=x, s=s, N=N, N_societies=N_societies)

# Make the type callable with the parameters *as a single argument*.

function (model::KlineModel)(θ)
    @unpack y, x, s, N, N_societies = model   # data
    @unpack β, α, σ = θ  # parameters
    ll = 0.0
    ll += logpdf(Cauchy(0, 1), σ)
    ll += sum(logpdf.(Normal(0, σ), α)) # α[1:10]
    ll += logpdf.(Normal(0, 10), β[1]) # a
    ll += logpdf.(Normal(0, 1), β[2]) # a
    ll += sum(
      [loglikelihood(Poisson(exp(α[s[i]] + dot(x[i, :], β))), [y[i]]) for i in 1:N]
    )
    ll
end

println()
θ = (β = [1.0, 0.25], α = rand(Normal(0, 1), N_societies), σ = 0.2)
model(θ) |> display
println()

# Wrap the problem with a transformation, then use Flux for the gradient.

P = TransformedLogDensity(make_transformation(model), model)
∇P = ADgradient(:ForwardDiff, P);
results = mcmc_with_warmup(Random.GLOBAL_RNG, ∇P, 1000)
posterior = P.transformation.(results.chain)

println()
DynamicHMC.Diagnostics.EBFMI(results.tree_statistics) |> display

println()
DynamicHMC.Diagnostics.summarize_tree_statistics(results.tree_statistics) |> display
println()

# Set varable names

parameter_names = ["a", "bp", "sigma_society"]
pooled_parameter_names = ["a_society[$i]" for i in 1:10]

# Create a3d

a3d = Array{Float64, 3}(undef, 1000, 13, 1);
for j in 1:1
  for i in 1:1000
    a3d[i, 1:2, j] = values(posterior[i].β)
    a3d[i, 3, j] = values(posterior[i].σ)
    a3d[i, 4:13, j] = values(posterior[i].α)
  end
end

chns = MCMCChains.Chains(a3d,
  vcat(parameter_names, pooled_parameter_names),
  Dict(
    :parameters => parameter_names,
    :pooled => pooled_parameter_names
  )
);

stan_result = "
Iterations = 1:1000
Thinning interval = 1
Chains = 1,2,3,4
Samples per chain = 1000

Empirical Posterior Estimates:
                            Mean                SD               Naive SE             MCSE            ESS    
            a          1.076167468  0.7704872560 0.01218247319 0.0210530022 1000.000000
           bp         0.263056273  0.0823415805 0.00130193470 0.0022645077 1000.000000
  a_society.1   -0.191723568  0.2421382537 0.00382854195 0.0060563054 1000.000000
  a_society.2    0.054569029  0.2278506876 0.00360263570 0.0051693148 1000.000000
  a_society.3   -0.035935050  0.1926364647 0.00304584994 0.0039948433 1000.000000
  a_society.4    0.334355037  0.1929971201 0.00305155241 0.0063871707  913.029080
  a_society.5    0.049747513  0.1801287716 0.00284808595 0.0043631095 1000.000000
  a_society.6   -0.311903245  0.2096126337 0.00331426674 0.0053000536 1000.000000
  a_society.7    0.148637507  0.1744680594 0.00275858223 0.0047660246 1000.000000
  a_society.8   -0.164567976  0.1821341074 0.00287979309 0.0034297298 1000.000000
  a_society.9    0.277066965  0.1758237250 0.00278001719 0.0055844175  991.286501
 a_society.10   -0.094149204  0.2846206232 0.00450024719 0.0080735022 1000.000000
sigma_society    0.310352849  0.1374834682 0.00217380450 0.0057325226  575.187461
";
        
# Describe the chain

describe(chns) |> display
println()

# Describe the chain

describe(chns, sections=[:pooled])

