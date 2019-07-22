using DynamicHMCModels, Random
using ProbabilityModels, DistributionParameters, VectorizationBase
using LoopVectorization
using LogDensityProblems, DynamicHMC, LinearAlgebra, Random
using Statistics, MCMCChains

# Load Julia packages (libraries) needed  for the snippets in chapter 0

Random.seed!(12345)

ProjDir = rel_path_d("..", "scripts", "10")
cd(ProjDir)

# ### snippet 10.4

d = CSV.read(rel_path("..", "data", "chimpanzees.csv"), delim=';');
df = convert(DataFrame, d);
df[!, :pulled_left] = convert(Array{Int64}, df[!, :pulled_left])
df[!, :prosoc_left] = convert(Array{Int64}, df[!, :prosoc_left])
df[!, :condition] = convert(Array{Int64}, df[!, :condition])
df[!, :actor] = convert(Array{Int64}, df[!, :actor])
first(df, 5)

ProjDir = @__DIR__
cd(ProjDir)

#=
@model m10.4p{
    vector[N] p;
    bpC ~ normal( 0 , 10 );
    bp ~ normal( 0 , 10 );
    a ~ normal( 0 , 10 );
    for ( i in 1:504 ) {
        p[i] = a[actor[i]] + (bp + bpC * condition[i]) * prosoc_left[i];
        p[i] = inv_logit(p[i]);
    }
    pulled_left ~ binomial( 1 , p );
}
=#

@model LogisticRegressionModel begin 
  β0 ~ Normal(μ0, σ0)
  β1 ~ Normal(μ1, σ1)
  y ~ Bernoulli_logit(β0 + X * β1)
end

Random.seed!(123597)
N=800;N_β =4;
X = randn(N, N_β); # N x N_β matrix of random normal samples
β1 = [-1.6, -1.75, -0.26, 0.65];
β0 = -0.05;
Xβ1=X* β1;

# N random uniform numbers between 0 and 1

p = rand(N); 

# inverse logit; generate random observations 

y = @. p < 1 / (1 + exp( - Xβ1 - β0)); 
sum(y) |> display # how many ys are true?

l_logistic = LogisticRegressionModel( μ0=0.0, σ0=10.0, μ1=0.0, σ1=5.0,
  β0 = RealFloat, β1 = RealVector{4}, y = y, X = X );

println("\nProbabilityModels result:\n")
@time mcmc_chain, tuned_sampler =
  NUTS_init_tune_mcmc_default(l_logistic, 40000);

pm_sample_matrix = get_position_matrix(mcmc_chain)
pm = reshape(pm_sample_matrix, 40000, 5, 1)

ns = fieldnames(LogisticRegressionModel)
pars = ["β1[$i]" for i in 1:length(β1)]
if findall(x -> x == :β0, ns) > findall(x -> x == :β1, ns)
  pars = append!(pars, ["β0"])
else
  pars = append!( ["β0"], pars)
end
pm_chns = Chains(pm, pars)
write("lr_pm_01.jls", pm_chns)

using MCMCDiagnostics

df = describe(pm_chns)
df[!, 1].df[!, :ess] = [effective_sample_size(pm[:, i]) for i ∈ 1:size(pm, 2)]
df |> display
println()

println("\nCmdStan result:\n")
include("lr_stan.jl")
