using StanModels

# CmdStan uses a tmp directory to store the output of cmdstan

ProjDir = @__DIR__
cd(ProjDir)

# ### snippet 10.4

d = CSV.read(rel_path("..", "data", "chimpanzees.csv"), delim=';');
df = convert(DataFrame, d);

first(df, 5)

# Define the Stan language model

m_10_04 = "
data{
    int N;
    int N_actors;
    int pulled_left[N];
    int prosoc_left[N];
    int condition[N];
    int actor[N];
}
parameters{
    vector[N_actors] a;
    real bp;
    real bpC;
}
model{
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
";

# Define the Stanmodel and set the output format to :mcmcchains.

stanmodel = Stanmodel(name="m_10_04", 
model=m_10_04, output_format=:mcmcchains);

# Input data for cmdstan

m_10_04_data = Dict("N" => size(df, 1), "N_actors" => length(unique(df[!, :actor])), 
"actor" => df[!, :actor], "pulled_left" => df[!, :pulled_left],
"prosoc_left" => df[!, :prosoc_left], "condition" => df[!, :condition]);

# Sample using cmdstan

rc, chn, cnames = stan(stanmodel, m_10_04_data, ProjDir, diagnostics=false,
  summary=true, CmdStanDir=CMDSTAN_HOME);

# Result rethinking

rethinking = "
      mean   sd  5.5% 94.5% n_eff Rhat
bp    0.84 0.26  0.43  1.26  2271    1
bpC  -0.13 0.29 -0.59  0.34  2949    1

a[1] -0.74 0.27 -1.16 -0.31  3310    1
a[2] 10.88 5.20  4.57 20.73  1634    1
a[3] -1.05 0.28 -1.52 -0.59  4206    1
a[4] -1.05 0.28 -1.50 -0.60  4133    1
a[5] -0.75 0.27 -1.18 -0.32  4049    1
a[6]  0.22 0.27 -0.22  0.65  3877    1
a[7]  1.81 0.39  1.22  2.48  3807    1
";

# Update sections 

chn2 = set_section(chn, Dict(
  :parameters => ["bp", "bpC"],
  :pooled => ["a.$i" for i in 1:7],
  :internals => ["lp__", "accept_stat__", "stepsize__", "treedepth__", "n_leapfrog__",
    "divergent__", "energy__"]
  )
)

# Describe parameter draws

describe(chn2)

# Describe pooled parameter draws

describe(chn2, sections=[:pooled])

# Make it a DataFrame

df = DataFrame(chn2, [:parameters, :pooled])

# End of `10/m10.04s.jl`
