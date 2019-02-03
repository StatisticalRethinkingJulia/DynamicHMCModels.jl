using StatisticalRethinkingDynamicHMC
using Turing

Turing.setadbackend(:reverse_diff)
#nbTuring.turnprogress(false);

d = CSV.read(joinpath(dirname(Base.pathof(StatisticalRethinkingDynamicHMC)), "..", "data",
    "chimpanzees.csv"), delim=';');
size(d) # Should be 504x8

# Turing model: pulled_left, actor, condition, prosoc_left

@model m12_4(pulled_left, actor, condition, prosoc_left) = begin
    # Total num of y
    N = length(pulled_left)
    # Separate σ priors for each actor
    σ_actor ~ Truncated(Cauchy(0, 1), 0, Inf)

    # Number of unique actors in the data set
    N_actor = length(unique(actor)) #7

    # Vector of actors (1,..,7) which we'll set priors on
    α_actor = Vector{Real}(undef, N_actor)

    # For each actor [1,..,7] set a prior N(0,σ_actor)
    α_actor ~ [Normal(0, σ_actor)]

    # Prior for intercept, prosoc_left, and the interaction
    α ~ Normal(0, 10)
    βp ~ Normal(0, 10)
    βpC ~ Normal(0, 10)

    logitp = [α + α_actor[actor[i]] +
            (βp + βpC * condition[i]) * prosoc_left[i]
            for i = 1:N]

    # Thanks to Kai Xu for suggesting ones(Int64, N)
    pulled_left ~ VecBinomialLogit(ones(Int64, N), logitp)

end

# Sample

posterior = sample(m12_4(
    Vector{Int64}(d[:pulled_left]),
    Vector{Int64}(d[:actor]),
    Vector{Int64}(d[:condition]),
    Vector{Int64}(d[:prosoc_left])),
    Turing.NUTS(5000, 1000, 0.95));

# Draw summary

describe(posterior)

m124rethinking = "
#             Mean StdDev lower 0.89 upper 0.89 n_eff Rhat
# a_actor[1]  -1.13   0.95      -2.62       0.27  2739    1
# a_actor[2]   4.17   1.66       1.80       6.39  3958    1
# a_actor[3]  -1.44   0.95      -2.90      -0.02  2720    1
# a_actor[4]  -1.44   0.94      -2.92      -0.04  2690    1
# a_actor[5]  -1.13   0.94      -2.58       0.31  2727    1
# a_actor[6]  -0.19   0.94      -1.64       1.25  2738    1
# a_actor[7]   1.34   0.97      -0.09       2.87  2889    1
# a            0.42   0.93      -1.00       1.81  2622    1
# bp           0.83   0.26       0.41       1.25  8594    1
# bpC         -0.13   0.30      -0.62       0.34  8403    1
# sigma_actor  2.26   0.94       1.07       3.46  4155    1
";
