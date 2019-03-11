# # Linear regression

using DynamicHMCModels, MCMCChains

ProjDir = rel_path_d("..", "scripts", "05")
cd(ProjDir)

# Import the dataset.

# ### snippet 5.1

wd = CSV.read(rel_path("..", "data", "WaffleDivorce.csv"), delim=';')
df = convert(DataFrame, wd);
mean_ma = mean(df[:MedianAgeMarriage])
df[:MedianAgeMarriage_s] = convert(Vector{Float64},
  (df[:MedianAgeMarriage]) .- mean_ma)/std(df[:MedianAgeMarriage]);

# Show the first six rows of the dataset.

first(df, 6)

# Model ``y ∼ Normal(y - Xβ, σ)``. Flat prior for `β`, half-T for `σ`.

struct WaffleDivorceProblem{TY <: AbstractVector, TX <: AbstractMatrix}
    "Observations."
    y::TY
    "Covariates"
    X::TX
end

# Make the type callable with the parameters *as a single argument*.

function (problem::WaffleDivorceProblem)(θ)
    @unpack y, X, = problem   # extract the data
    @unpack β, σ = θ            # works on the named tuple too
    ll = 0.0
    ll += logpdf(Normal(10, 10), X[1]) # a = X[1]
    ll += logpdf(Normal(0, 1), X[2]) # b1 = X[2]
    ll += logpdf(TDist(1.0), σ)
    ll += loglikelihood(Normal(0, σ), y .- X*β)
    ll
end

# Instantiate the model with data and inits.

N = size(df, 1)
X = hcat(ones(N), df[:MedianAgeMarriage_s]);
y = convert(Vector{Float64}, df[:Divorce])
p = WaffleDivorceProblem(y, X);
p((β = [1.0, 2.0], σ = 1.0))

# Write a function to return properly dimensioned transformation.

problem_transformation(p::WaffleDivorceProblem) =
    as((β = as(Array, size(p.X, 2)), σ = asℝ₊))

# Wrap the problem with a transformation, then use Flux for the gradient.

P = TransformedLogDensity(problem_transformation(p), p)
∇P = LogDensityRejectErrors(ADgradient(:ForwardDiff, P));

# Create an array to hold 1000 samples of 3 parameters in 4 chains

a3d = create_a3d(1000, 3, 4);
trans = as( (β = as(Array, 2), σ = asℝ));

# Sample from 4 chains and store the draws in the a3d array

for j in 1:4
  chain, NUTS_tuned = NUTS_init_tune_mcmc(∇P, 3000);
  posterior = TransformVariables.transform.(Ref(problem_transformation(p)), 
    get_position.(chain));
  insert_chain!(a3d, j, posterior, trans);
end;

cnames = ["a", "bA", "sigma"]
chns = Chains(a3d, cnames)

# cmdstan result

cmdstan_result = "
Iterations = 1:1000
Thinning interval = 1
Chains = 1,2,3,4
Samples per chain = 1000

Empirical Posterior Estimates:
         Mean        SD       Naive SE       MCSE      ESS
    a  9.6882466 0.22179190 0.0035068378 0.0031243061 1000
   bA -1.0361742 0.21650514 0.0034232469 0.0034433245 1000
sigma  1.5180337 0.15992781 0.0025286807 0.0026279593 1000

Quantiles:
         2.5%      25.0%     50.0%      75.0%       97.5%   
    a  9.253141  9.5393175  9.689585  9.84221500 10.11121000
   bA -1.454571 -1.1821025 -1.033065 -0.89366925 -0.61711705
sigma  1.241496  1.4079225  1.504790  1.61630750  1.86642750
";

# Extract the parameter posterior means: `β`,

describe(chns)

# Plot the chains

plot(chns)

# end of m4.5d.jl