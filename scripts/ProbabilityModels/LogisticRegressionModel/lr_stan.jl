using CmdStan

ProjDir = @__DIR__
cd(ProjDir)
           
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

logistic_data_dict = Dict(
   "N" => N, "y" => convert(Vector{Int32}, y), "X" => X,
   "mu0" => 0, "mu1" => 0, "sigma0" => 10, "sigma1" => 5
);


stanmodel_logistic_glm = Stanmodel(
   name = "logistic_glm", Sample(num_samples=40000, num_warmup=900),
   model = bernoulli_logit_glm, nchains = 1);

#=
stanmodel_logistic_glm = Stanmodel(
  name = "logistic_glm", Sample(num_samples=40000, num_warmup=900),
  model = bernoulli_logit_glm, nchains = 1);
=#
   
@time rc_glm, chns_stan, cnames_glm = stan(stanmodel_logistic_glm,
  logistic_data_dict, summary=false, ProjDir);

write("lr_stan_01.jls", chns_stan)

describe(chns_stan)