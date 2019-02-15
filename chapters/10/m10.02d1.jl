using DynamicHMCModels, Optim

d = CSV.read(rel_path("..", "data", "chimpanzees.csv"), delim=';');
df = convert(DataFrame, d);
df[:pulled_left] = convert(Array{Int64}, df[:pulled_left])
df[:prosoc_left] = convert(Array{Int64}, df[:prosoc_left])
first(df, 5)

struct m_10_02d{TY <: AbstractVector, TX <: AbstractMatrix}
    "Observations."
    y::TY
    "Covariates"
    X::TX
    "Number of observations"
    N::Int
end

function (problem::m_10_02d)(θ)
    @unpack y, X, N = problem   # extract the data
    @unpack β = trans(θ)  # works on the named tuple too
    ll = 0.0
    ll += sum(logpdf.(Normal(0, 10), β)) # a & bp
    ll += sum([loglikelihood(Binomial(1, logistic(dot(X[i, :], β))), [y[i]]) for i in 1:N])
    ll
end

N = size(df, 1)
X = hcat(ones(Int64, N), df[:prosoc_left]);
y = df[:pulled_left]
p = m_10_02d(y, X, N);

trans = as( (β = as(Array, size(p.X, 2)), ));

γ =  (β = [0.5, 1.0],)
θ = inverse(trans, γ)
p(θ)

x0 = θ;
lower = [-1.0, -1.0];
upper = [1.0, 2.0];
ll(x) = -p(x)

inner_optimizer = GradientDescent()

optimize(ll, lower, upper, x0, Fminbox(inner_optimizer))

problem_transformation(p::m_10_02d) =

      as( Vector, size(p.X, 2))

P = TransformedLogDensity(problem_transformation(p), p)
∇P = LogDensityRejectErrors(ADgradient(:ForwardDiff, P));

chain, NUTS_tuned = NUTS_init_tune_mcmc(∇P, 1000);

posterior = TransformVariables.transform.(Ref(problem_transformation(p)), get_position.(chain));
posterior[1:5]

posterior_a = mean(first, posterior)
posterior_bp = mean(last, posterior)

ess = mapslices(effective_sample_size, get_position_matrix(chain); dims = 1)
ess

NUTS_statistics(chain)

m_10_2s_result = "
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

[posterior_a, posterior_bp]

# This file was generated using Literate.jl, https://github.com/fredrikekre/Literate.jl

