### A Pluto.jl notebook ###
# v0.19.25

using Markdown
using InteractiveUtils

# ╔═╡ 424a382b-3d1a-4888-b45e-af676ed609fd
using Pkg

# ╔═╡ 63c8eae3-10f8-4d14-8576-5fddadf320ef
Pkg.activate(expanduser("~/.julia/dev/DynamicHMCModels"))

# ╔═╡ 9822ccca-1ff4-414e-a24a-9df9b6cdb2d8
begin
	using DynamicHMCModels
	using RegressionAndOtherStories
end

# ╔═╡ f4665abd-ced7-46d6-ae85-3b4a1a7a389a
md" ## Statistical Rethinking m5.1d.jl"

# ╔═╡ 7611fa31-9981-4c21-a899-0d8916895ca3
html"""
<style>
	main {
		margin: 0 auto;
		max-width: 3500px;
    	padding-left: max(10px, 5%);
    	padding-right: max(10px, 5%);
	}
</style>
"""

# ╔═╡ cfc3e3ac-1909-43a4-82e6-3ecf8157918a
ProjDir = expanduser("~/.julia/dev/DynamicHMCModels")

# ╔═╡ 288be972-c05e-459a-b680-3478691ffb7e
cd(ProjDir)

# ╔═╡ ec5e4789-57b4-4ee0-8bfd-9cce9190ae7b
# Import the dataset.
begin
    df = CSV.read(joinpath(ProjDir, "data", "WaffleDivorce.csv"), DataFrame)
    mean_ma = mean(df[:, :MedianAgeMarriage])
    df[!, :MedianAgeMarriage_s] = convert(Vector{Float64},
      (df[:, :MedianAgeMarriage]) .- mean_ma)/std(df[:, :MedianAgeMarriage]);
	df
end

# ╔═╡ e93d3862-bcfb-40ea-b24a-15a6a5f7c688
# Model ``y ∼ Normal(y - Xβ, σ)``. Flat prior `β`, half-T for `σ`.

begin
    struct WaffleDivorce{Ty <: AbstractVector, Tx <: AbstractMatrix}
        "Observations."
        y::Ty
        "Covariates"
        x::Tx
    end

    # Write a function to return a properly dimensioned transformation.

    function make_transformation(model::WaffleDivorce)
      as((β = as(Array, size(model.x, 2)), σ = asℝ₊))
    end

    # Make tmodel callable with the parameters *as a single argument*.

    function (model::WaffleDivorce)(θ)
        @unpack y, x = model   # extract the data
        @unpack β, σ = θ            # works on the named tuple too
        ll = 0.0
        ll += logpdf(Normal(10, 10), x[1]) # alpha
        ll += logpdf(Normal(0, 1), x[2]) # beta
        ll += logpdf(TDist(1.0), σ)
        ll += loglikelihood(Normal(0, σ), y .- x*β)
        ll
    end

end

# ╔═╡ ca60a4d1-607d-4a1c-b66f-9450df075473
# Instantiate the model with data and inits.
x = hcat(ones(size(df, 1)), df[:, :MedianAgeMarriage_s]);

# ╔═╡ 9746e793-dbf1-41ed-9391-a3adee0dc15d
p = WaffleDivorce(df[:, :Divorce], x);

# ╔═╡ 7ac3ee84-6569-4cd4-9f70-31e82b6480fe
p((β = [1.0, 2.0], σ = 1.0)) |> display

# ╔═╡ 17ed9a86-39d1-4056-b37a-689b23e4e32b
t = make_transformation(p)

# ╔═╡ 33f95df5-7a4c-4216-a3dd-e3d4c07984d3
# Wrap the problem with a transformation, then use Flux for the gradient.
P = TransformedLogDensity(t, p)

# ╔═╡ 5c3072b4-0914-4170-8363-cb5ff66e6595
∇P = ADgradient(:ForwardDiff, P);

# ╔═╡ 8cfcbf0a-83eb-4fbf-9c21-f36419da299f
# Tune and sample (4 chains).
results = map(_ -> mcmc_with_warmup(Random.GLOBAL_RNG, ∇P, 1000), 1:4)

# ╔═╡ 659c5897-fe6a-4501-a019-6cdc881f0207
posterior = TransformVariables.transform.(t, eachcol(pool_posterior_matrices(results)));

# ╔═╡ 7110abf6-6af6-4727-8080-859ad176037a
posterios_σ = round(mean(last, posterior); digits=2)

# ╔═╡ 4e1bee66-dfc0-4fd8-bdca-b53e7de59150
posterios_β = round.(mean(first, posterior); digits=2)

# ╔═╡ a5462745-d8e5-42f8-9ea9-60591b6ab412
stan_result = "
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

# ╔═╡ ca1dcbbf-8d0f-4039-aed3-0e8cacda3abd
md" ##### End of m5.1d.jl"

# ╔═╡ Cell order:
# ╠═f4665abd-ced7-46d6-ae85-3b4a1a7a389a
# ╠═7611fa31-9981-4c21-a899-0d8916895ca3
# ╠═424a382b-3d1a-4888-b45e-af676ed609fd
# ╠═63c8eae3-10f8-4d14-8576-5fddadf320ef
# ╠═9822ccca-1ff4-414e-a24a-9df9b6cdb2d8
# ╠═cfc3e3ac-1909-43a4-82e6-3ecf8157918a
# ╠═288be972-c05e-459a-b680-3478691ffb7e
# ╠═ec5e4789-57b4-4ee0-8bfd-9cce9190ae7b
# ╠═e93d3862-bcfb-40ea-b24a-15a6a5f7c688
# ╠═ca60a4d1-607d-4a1c-b66f-9450df075473
# ╠═9746e793-dbf1-41ed-9391-a3adee0dc15d
# ╠═7ac3ee84-6569-4cd4-9f70-31e82b6480fe
# ╠═17ed9a86-39d1-4056-b37a-689b23e4e32b
# ╠═33f95df5-7a4c-4216-a3dd-e3d4c07984d3
# ╠═5c3072b4-0914-4170-8363-cb5ff66e6595
# ╠═8cfcbf0a-83eb-4fbf-9c21-f36419da299f
# ╠═659c5897-fe6a-4501-a019-6cdc881f0207
# ╠═7110abf6-6af6-4727-8080-859ad176037a
# ╠═4e1bee66-dfc0-4fd8-bdca-b53e7de59150
# ╠═a5462745-d8e5-42f8-9ea9-60591b6ab412
# ╟─ca1dcbbf-8d0f-4039-aed3-0e8cacda3abd
