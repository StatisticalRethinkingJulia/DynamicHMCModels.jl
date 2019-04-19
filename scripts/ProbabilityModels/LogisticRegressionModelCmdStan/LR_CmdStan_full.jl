using CmdStan, StatsPlots, Random
gr(size=(400,400))

ProjDir = @__DIR__
cd(ProjDir)
           
bernoulli_logit = "
  data {
   int<lower=0> N;
   int y[N];
   matrix[N,4] X;
   real mu0;
   real mu1;
   real sigma0;
   real sigma1;
  }
  parameters {
   real beta0;
   vector[4] beta1;
  }
  model {
   beta0 ~ normal(mu0, sigma0);
   beta1 ~ normal(mu1, sigma1);
   // y ~ bernoulli_logit_glm(X, beta0, beta1);
   y ~ bernoulli_logit(beta0 + X * beta1);
  }
";

bernoulli_logit_glm = "
  data {
   int<lower=0> N;
   int y[N];
   matrix[N,4] X;
   real mu0;
   real mu1;
   real sigma0;
   real sigma1;
  }
  parameters {
   real beta0;
   vector[4] beta1;
  }
  model {
   beta0 ~ normal(mu0, sigma0);
   beta1 ~ normal(mu1, sigma1);
   y ~ bernoulli_logit_glm(X, beta0, beta1);
   // y ~ bernoulli_logit(beta0 + X * beta1);
}
";

Random.seed!(123597)
N=800;N_β =4;
X = randn(N, N_β); # N x N_β matrix of random normal samples
β1 = [-1.6, -1.75, -0.26, 0.65];
β0 = -0.05
Xβ1=X* β1;

# N random uniform numbers between 0 and 1

p = rand(N); 

# inverse logit; generate random observations 

y = @. p < 1 / (1 + exp( - Xβ1 - β0)); 
sum(y) |> display # how many ys are true?

logistic_data_dict = Dict(
   "N" => N, "y" => convert(Vector{Int32}, y), "X" => X,
   "mu0" => 0, "mu1" => 0, "sigma0" => 10, "sigma1" => 5
);

stanmodel_logistic = Stanmodel(
  name = "logistic", Sample(num_samples=10000,num_warmup=900),
  model = bernoulli_logit, nchains = 4);
  
stanmodel_logistic_glm = Stanmodel(
   name = "logistic_glm", Sample(num_samples=10000, num_warmup=900),
   model = bernoulli_logit_glm, nchains = 4);

@time rc, chns, cnames = stan(stanmodel_logistic, logistic_data_dict,
  summary=false, ProjDir);

@time rc_glm, chns_glm, cnames_glm = stan(stanmodel_logistic_glm,
  logistic_data_dict, summary=false, ProjDir);
  
println()
if rc == 0
  if isdefined(Main, :StatsPlots)
    p1 = plot(chns)
    savefig(p1, "logistic.pdf")
    savefig(p1, "logistic.png")
    p2 = pooleddensity(chns)
    savefig(p2, "pooledensity_logistic.pdf")
    savefig(p2, "pooledensity_logistic.png")
  end
  show(chns)
  println()
end

if rc_glm == 0
  println()
  if isdefined(Main, :StatsPlots)
    p3 = plot(chns_glm)
    savefig(p3, "logistic_glm.pdf")
    savefig(p3, "logistic_glm.png")
    p4 = pooleddensity(chns_glm)
    savefig(p4, "pooledensity_logistic_glm.pdf")
    savefig(p4, "pooledensity_logistic_glm.png")
  end
  show(chns_glm)
  println()
end

if rc == 0
  describe(chns_glm, showall=true)
end