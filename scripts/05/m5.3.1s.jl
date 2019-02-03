# Load Julia packages (libraries) needed  for the snippets in chapter 0

using StatisticalRethinkingDynamicHMC
using CmdStan, StanMCMCChain
gr(size=(500,500));

# CmdStan uses a tmp directory to store the output of cmdstan

ProjDir = rel_path_d("..", "scripts", "05")
cd(ProjDir)

# ### snippet 5.1

wd = CSV.read(rel_path_d("..", "data", "WaffleDivorce.csv"), delim=';')
df = convert(DataFrame, wd);

mean_ma = mean(df[:Marriage])
df[:Marriage_s] = convert(Vector{Float64},
  (df[:Marriage]) .- mean_ma)/std(df[:Marriage]);

mean_mam = mean(df[:MedianAgeMarriage])
df[:MedianAgeMarriage_s] = convert(Vector{Float64},
  (df[:MedianAgeMarriage]) .- mean_mam)/std(df[:MedianAgeMarriage]);
  
first(df[[1, 7, 14,15]], 6)

# Define the Stan language model

m5_3_1_model = "
data {
  int N;
  vector[N] divorce;
  vector[N] marriage_z;
  vector[N] median_age_z;
}
parameters {
  real a;
  real bA;
  real bM;
  real<lower=0> sigma;
}
model {
  vector[N] mu = a + median_age_z * bA + marriage_z * bM;
  target += normal_lpdf(divorce | mu, sigma);
  target += normal_lpdf(a | 10, 10);
  target += normal_lpdf(bA | 0, 10);
  target += normal_lpdf(bM | 0, 10);
  target += exponential_lpdf(sigma | 1);
}
";

# Define the Stanmodel and set the output format to :mcmcchain.

stanmodel = Stanmodel(name="m5_3_1_model",
monitors = ["a", "bA", "bR", "sigma", "Divorce"],
 model=m5_3_1_model, output_format=:mcmcchain);

# Input data for cmdstan

m5_3_1_data = Dict("N" => size(df, 1), "divorce" => df[:Divorce],
    "marriage_z" => df[:Marriage_s], "median_age_z" => df[:MedianAgeMarriage_s]);

# Sample using cmdstan

rc, chn, cnames = stan(stanmodel, m5_3_1_data, ProjDir, diagnostics=false,
  summary=true, CmdStanDir=CMDSTAN_HOME);

# Describe the draws

describe(chn)

# Rethinking results

rethinking_results = "
       mean   sd  5.5% 94.5% n_eff Rhat
a      9.69 0.22  9.34 10.03  1313    1
bR    -0.12 0.30 -0.60  0.35   932    1
bA    -1.13 0.29 -1.56 -0.67   994    1
sigma  1.53 0.16  1.28  1.80  1121    1
"

#=
# Plot the density of posterior draws

plot(chn)

# Plot regression line using means and observations

xi = -3.0:0.01:3.0
rws, vars, chns = size(chn[:, 1, :])
alpha_vals = convert(Vector{Float64}, reshape(chn.value[:, 1, :], (rws*chns)))
beta_vals = convert(Vector{Float64}, reshape(chn.value[:, 2, :], (rws*chns)))
yi = mean(alpha_vals) .+ mean(beta_vals)*xi

scatter(df[:MedianAgeMarriage_s], df[:Divorce], color=:darkblue,
  xlab="Median age of marriage [ $(round(mean_mam, digits=1)) years]",
  ylab="divorce rate [# of divorces/1000 adults]")
plot!(xi, yi, lab="Regression line")

# shade(), abline() and link()

mu = link(xi, chn, [1, 2], mean(xi));
yl = [minimum(mu[i]) for i in 1:length(xi)];
yh =  [maximum(mu[i]) for i in 1:length(xi)];
ym =  [mean(mu[i]) for i in 1:length(xi)];
pi = hcat(xi, yl, ym, yh);
pi[1:5,:]

plot!((xi, yl), color=:lightgrey, leg=false)
plot!((xi, yh), color=:lightgrey, leg=false)
for i in 1:length(xi)
  plot!([xi[i], xi[i]], [yl[i], yh[i]], color=:lightgrey, leg=false)
end
scatter!(df[:MedianAgeMarriage_s], df[:Divorce], color=:darkblue)
plot!(xi, yi, lab="Regression line")
=#

# End of `05/5.3s.jl`
