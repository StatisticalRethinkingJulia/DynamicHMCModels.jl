
using ProbabilityModels, DistributionParameters, VectorizationBase
using LoopVectorization
using LogDensityProblems, DynamicHMC, LinearAlgebra

@model LogisticRegressionModel begin β0 ~ Normal(μ0, σ0)
  β1 ~ Normal(μ1, σ1)
  y ~ Bernoulli_logit(β0 + X * β1)
end

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

@time mcmc_chain, tuned_sampler =
  NUTS_init_tune_mcmc_default(l_logistic, 40000);
  