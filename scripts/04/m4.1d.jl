begin
    using DynamicHMCModels
    using BenchmarkTools
    using RegressionAndOtherStories
end

ProjDir = expanduser("~/.julia/dev/DynamicHMCModels")

howell1 = CSV.read(joinpath(ProjDir, "data", "Howell1.csv"), DataFrame)

df = filter(row -> row[:age] >= 18, howell1);

begin
    struct Heights{Ty <: AbstractVector, Tν <: Real}
        "Observations."
        y::Ty
        "Degrees of freedom for prior on sigma."
        v::Tν
    end

    function make_transformation(model::Heights)
        as((σ = asℝ₊, μ  = as(Real, 100, 250)), )
    end

    function (model::Heights)(θ)
        @unpack y, v = model   # extract the data
        @unpack μ, σ = θ
        # Half-T for `σ`
        loglikelihood(Normal(μ, σ), y) + logpdf(TDist(v), σ)
    end
end

p = Heights(df[:, :height], 1.0)

p((μ=150.0, σ=7.7))

t = make_transformation(p)

P = TransformedLogDensity(t, p)

∇P = ADgradient(:ForwardDiff, P);

results = map(_ -> mcmc_with_warmup(Random.GLOBAL_RNG, ∇P, 1000), 1:4)

posterior = TransformVariables.transform.(t, eachcol(pool_posterior_matrices(results)))

posterior_σ = round(mean(first, posterior); digits=2)

posterior_μ = round(mean(last, posterior); digits=2)

# Stan.jl results

cmdstan_result = "
Iterations = 1:1000
Thinning interval = 1
Chains = 1,2,3,4
Samples per chain = 1000

Empirical Posterior Estimates:
          Mean        SD       Naive SE      MCSE      ESS
sigma   7.7641872 0.29928194 0.004732063 0.0055677898 1000
   mu 154.6055177 0.41989355 0.006639100 0.0085038356 1000

Quantiles:
         2.5%      25.0%       50.0%      75.0%       97.5%  
sigma   7.21853   7.5560625   7.751355   7.9566775   8.410391
   mu 153.77992 154.3157500 154.602000 154.8820000 155.431000
";

ess, R̂ = ess_rhat(stack_posterior_matrices(results))

summarize_tree_statistics(mapreduce(x -> x.tree_statistics, vcat, results))
