# Load Julia packages (libraries) needed  for the snippets in chapter 0

using DynamicHMCModels, ForwardDiff, Flux, ReverseDiff
gr(size=(400,400))

# CmdStan uses a tmp directory to store the output of cmdstan

ProjDir = rel_path_d("..", "scripts", "10")
cd(ProjDir)

# ### snippet 10.4

d = CSV.read(rel_path("..", "data", "chimpanzees.csv"), delim=';');
df = convert(DataFrame, d);
df[!, :pulled_left] = convert(Array{Int64}, df[!, :pulled_left])
df[!, :prosoc_left] = convert(Array{Int64}, df[!, :prosoc_left])
df[!, :condition] = convert(Array{Int64}, df[!, :condition])
df[!, :actor] = convert(Array{Int64}, df[!, :actor])
first(df[!, [:actor, :pulled_left, :prosoc_left, :condition]], 5)

struct m_10_04d_model{TY <: AbstractVector, TX <: AbstractMatrix,
  TA <: AbstractVector}
    "Observations."
    y::TY
    "Covariates"
    X::TX
    "Actors"
    A::TA
    "Number of observations"
    N::Int
    "Number of unique actors"
    N_actors::Int
end

# Make the type callable with the parameters *as a single argument*.

function (problem::m_10_04d_model)(θ)
    @unpack y, X, A, N, N_actors = problem   # extract the data
    @unpack β, α = θ  # works on the named tuple too
    ll = 0.0
    ll += sum(logpdf.(Normal(0, 10), β)) # bp & bpC
    ll += sum(logpdf.(Normal(0, 10), α)) # alpha[1:7]
    ll += sum(
      [loglikelihood(Binomial(1, logistic(α[A[i]] + dot(X[i, :], β))), [y[i]]) for i in 1:N]
    )
    ll
end

# Instantiate the model with data and inits.

N = size(df, 1)
N_actors = length(unique(df[!, :actor]))
X = hcat(ones(Int64, N) .* df[!, :prosoc_left], df[!, :prosoc_left] .* df[!, :condition]);
A = df[!, :actor]
y = df[!, :pulled_left]
p = m_10_04d_model(y, X, A, N, N_actors);
θ = (β = [1.0, 0.0], α = [-1.0, 10.0, -1.0, -1.0, -1.0, 0.0, 2.0])
p(θ)

# Write a function to return properly dimensioned transformation.

problem_transformation(p::m_10_04d_model) =
    as( (β = as(Array, size(p.X, 2)), α = as(Array, p.N_actors), ) )

# Wrap the problem with a transformation, then use Flux for the gradient.

P = TransformedLogDensity(problem_transformation(p), p)

# For stress testing

do_stresstest = false

#ad = :Flux
ad = :ForwardDiff
#ad = :ReverseDiff

if do_stresstest
  ∇P = ADgradient(:ForwardDiff, P);
  #st = LogDensityProblems.stresstest(p, N=1000, scale=1.0)
  #display(st)
else
  ∇P = LogDensityRejectErrors(ADgradient(ad, P));
end  

# Run single chains

chain, NUTS_tuned = NUTS_init_tune_mcmc(∇P, 3000);
posterior = TransformVariables.transform.(Ref(problem_transformation(p)),
  get_position.(chain));

# Result rethinking

rethinking = "
      mean   sd  5.5% 94.5% n_eff Rhat
a[1] -0.74 0.27 -1.19 -0.31  2899    1
a[2] 10.77 5.20  4.60 20.45  1916    1
a[3] -1.05 0.28 -1.50 -0.62  3146    1
a[4] -1.05 0.28 -1.50 -0.61  3525    1
a[5] -0.73 0.28 -1.17 -0.28  3637    1
a[6]  0.22 0.27 -0.21  0.67  3496    1
a[7]  1.82 0.41  1.21  2.50  3202    1
bp    0.83 0.27  0.42  1.27  2070    1
bpC  -0.13 0.31 -0.62  0.34  3430    1
";

# Set varable names, this will be automated using θ

parameter_names = ["bp", "bpC"]
pooled_parameter_names = ["a[$i]" for i in 1:7];

# Create a3d

a3d = Array{Float64, 3}(undef, 3000, 9, 1);
for i in 1:3000
  a3d[i, 1:2, 1] = values(posterior[i][1])
  a3d[i, 3:9, 1] = values(posterior[i][2])
end

chns = MCMCChains.Chains(a3d,
  vcat(parameter_names, pooled_parameter_names),
  Dict(
    :parameters => parameter_names,
    :pooled => pooled_parameter_names
  )
);

# Describe the chain

describe(chns)

# Describe the chain

describe(chns, sections=[:pooled])

# Plot the chain parameters

plot(chns)

# End of `m10.04d1.jl`
