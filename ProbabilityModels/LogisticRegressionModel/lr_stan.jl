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
   real b0;
   vector[4] b1;
  }
  model {
   b0 ~ normal(mu0, sigma0);
   b1 ~ normal(mu1, sigma1);
   y ~ bernoulli_logit_glm(X, b0, b1);
   // y ~ bernoulli_logit(b0 + X * b1);
}
";

logistic_data_dict = Dict(
   "N" => N, "y" => convert(Vector{Int32}, y), "X" => X,
   "mu0" => 0, "mu1" => 0, "sigma0" => 10, "sigma1" => 5
);

stanmodel_logistic_glm = Stanmodel(
   name = "logistic_glm", Sample(num_samples=1000, num_warmup=900),
   model = bernoulli_logit_glm, nchains = 4);
   
@time rc_glm, chns_stan, cnames_glm = stan(stanmodel_logistic_glm,
   logistic_data_dict, summary=true, ProjDir);

write("lr_stan_01.jls", chns_stan)

describe(chns_stan)