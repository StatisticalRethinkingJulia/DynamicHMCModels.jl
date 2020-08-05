using DynamicHMCModels, LinearAlgebra, StatsFuns

ProjDir = @__DIR__
cd(ProjDir)

delim = ';'
df = CSV.read(joinpath("..", "..", "data", "chimpanzees.csv"), DataFrame; delim)
df.pulled_left = convert(Array{Int64}, df.pulled_left)
df.prosoc_left = convert(Array{Int64}, df.prosoc_left)
first(df, 5)

Base.@kwdef mutable struct Chimpanzees{Ty <: AbstractVector,
  Tx <: AbstractMatrix}
    "Observations."
    y::Ty
    "Covariates"
    x::Tx
    "Number of observations"
    N::Int
end

# Write a function to return properly dimensioned transformation.

function make_transformation(model::Chimpanzees)
  as( (β = as(Array, size(model.x, 2)), ) )
end

# Instantiate the model with data and inits.

N = size(df, 1)
x = hcat(ones(Int64, N), df[:, :prosoc_left]);
y = df[:, :pulled_left]
model = Chimpanzees(;y=y, x=x, N=N);

# Make the model callable with a single argument.

function (model::Chimpanzees)(θ)
    @unpack y, x, N = model   # extract the data
    @unpack β = θ  # works on the named tuple too
    ll = 0.0
    ll += sum(logpdf.(Normal(0, 10), β)) # a & bp
    ll += sum([loglikelihood(Binomial(1, logistic(dot(x[i, :], β))), [y[i]]) for i in 1:N])
    ll
end

println()
θ = (β = [1.0, 2.0],)
model(θ)
println()

# Wrap the problem with a transformation, then use Flux for the gradient.

P = TransformedLogDensity(make_transformation(model), model)
∇P = ADgradient(:ForwardDiff, P)
results = mcmc_with_warmup(Random.GLOBAL_RNG, ∇P, 1000)
posterior = P.transformation.(results.chain)

p = as_particles(posterior)
display(p)

stan_result = "
Iterations = 1:1000
Thinning interval = 1
Chains = 1,2,3,4
Samples per chain = 1000

Empirical Posterior Estimates:
      Mean        SD       Naive SE       MCSE      ESS
 a 0.05103234 0.12579086 0.0019889282 0.0035186307 1000
bp 0.55711212 0.18074275 0.0028577937 0.0040160451 1000

Quantiles:
       2.5%        25.0%       50.0%      75.0%      97.5%  
 a -0.19755400 -0.029431425 0.05024655 0.12978825 0.30087758
bp  0.20803447  0.433720250 0.55340400 0.67960975 0.91466915
";

# End of `10/m10.2d.jl`
