### A Pluto.jl notebook ###
# v0.19.25

using Markdown
using InteractiveUtils

# ╔═╡ b1d75537-f57f-449f-bf1a-f45893d681e7
using Pkg

# ╔═╡ 8579cdbb-c00e-4ec0-9dd2-3bd49e0c2dc5
Pkg.activate(expanduser("~/.julia/dev/DynamicHMCModels"))

# ╔═╡ 2aeee6e5-5f5a-4dc1-a74e-e99681598b5b
begin
	using DynamicHMCModels
	using BenchmarkTools
	using RegressionAndOtherStories
end

# ╔═╡ 6858334e-3f06-4c24-97d6-eced685d2078
md" ## Statistical Rethinking m4.5d"

# ╔═╡ 0ddee595-577c-412c-b14d-e37e8631b84e
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

# ╔═╡ ac08a63f-2a11-4987-804a-2f43dd9f9528
ProjDir = expanduser("~/.julia/dev/DynamicHMCModels")

# ╔═╡ a9633f6f-6d03-4e9e-92aa-e4a7a4588671
md" ##### Import the dataset."

# ╔═╡ 0de0bacf-f5cf-4d32-b4c1-1db120646046
data = CSV.read(joinpath(ProjDir, "data", "Howell1.csv"), DataFrame)

# ╔═╡ 8c3d5446-fef0-4c22-b19a-0485d3739e77
md" ##### Use only adults and standardize."

# ╔═╡ 413f98e4-cfc3-4c65-8885-4bc3cad88224
begin
	df = filter(row -> row[:age] >= 18, data)
	df[!, :weight] = convert(Vector{Float64}, df[:, :weight])
	df[!, :weight_s] = (df[:, :weight] .- mean(df[:, :weight])) / std(df[:, :weight])
	df[!, :weight_s2] = df[:, :weight_s] .^ 2
	df
end

# ╔═╡ 24fd2a28-479d-4973-91f7-714d5c6c4845
# LR model ``y ∼ xβ + ϵ``, where ``ϵ ∼ N(0, σ²)`` IID.

# ╔═╡ 61609bf1-ca44-4446-8852-7ade37688a6e
begin

	struct Heights{Ty <: AbstractVector, Tx <: AbstractMatrix}
	    "Observations."
	    y::Ty
	    "Covariates"
	    x::Tx
	end

	# Write a function to return a properly dimensioned transformation.

	function make_transformation(model::Heights)
	  as((β = as(Array, size(model.x, 2)), σ = asℝ₊))
	end
	
	# Pack the parameters in a single argument θ.
	
	function (problem::Heights)(θ)
	    @unpack y, x = problem   # extract the data
	    @unpack β, σ = θ            # works on the named tuple too
	    ll = 0.0
	    ll += logpdf(Normal(178, 100), x[1]) # a = x[1]
	    ll += logpdf(Normal(0, 10), x[2]) # b1 = x[2]
	    ll += logpdf(Normal(0, 10), x[3]) # b2 = x[3]
	    ll += logpdf(TDist(1.0), σ)
	    ll += loglikelihood(Normal(0, σ), y .- x*β)
	    ll
	end
	
end

# ╔═╡ d3b3fdb1-8bb0-4aae-8af2-2f516bf926fe
begin
	N = size(df, 1)
	x = hcat(ones(N), hcat(df[:, :weight_s], df[:, :weight_s2]));
	p = Heights(df[:, :height], x)
end

# ╔═╡ 6357f5ff-5f9d-41df-b769-29873c7dca7c
p((β = [1.0, 2.0, 3.0], σ = 1.0))

# ╔═╡ 0c5ec62a-3ab8-4062-a98d-b27f57344828
t = make_transformation(p)

# ╔═╡ 80c789d5-94f6-4292-bd45-baf350f3f252
# Wrap the problem with a transformation, then use Flux for the gradient.

P = TransformedLogDensity(t, p)

# ╔═╡ bd3f658b-86d8-44f9-b45f-191b9e02a01e
∇P = ADgradient(:ForwardDiff, P);

# ╔═╡ 428a76c5-87e5-4e90-9e7a-0bd67b43f059
# Tune and sample.

results = map(_ -> mcmc_with_warmup(Random.GLOBAL_RNG, ∇P, 1000), 1:4)

# ╔═╡ 27fa1b35-c446-4ba8-9bc5-23380184aca2
posterior = TransformVariables.transform.(t, eachcol(pool_posterior_matrices(results)))

# ╔═╡ e87631a3-b41e-4abe-a5e9-b7b9814d89af
posterios_σ = round(mean(last, posterior); digits=2)

# ╔═╡ 7c20c076-95f1-47b6-934a-034cb4eb12b7
posterios_β = round.(mean(first, posterior); digits=2)

# ╔═╡ b5a362b7-e51b-4f40-97b0-755976c4dde0
stan_result = "
Iterations = 1:1000
Thinning interval = 1
Chains = 1,2,3,4
Samples per chain = 1000

Empirical Posterior Estimates:
           Mean         SD       Naive SE       MCSE      ESS
    a 154.609019750 0.36158389 0.0057171433 0.0071845548 1000
   b1   5.838431778 0.27920926 0.0044146860 0.0048693502 1000
   b2  -0.009985954 0.22897191 0.0036203637 0.0047224478 1000
sigma   5.110136300 0.19096315 0.0030193925 0.0030728192 1000

Quantiles:
          2.5%        25.0%        50.0%       75.0%        97.5%   
    a 153.92392500 154.3567500 154.60700000 154.8502500 155.32100000
   b1   5.27846200   5.6493250   5.83991000   6.0276275   6.39728200
   b2  -0.45954687  -0.1668285  -0.01382935   0.1423620   0.43600905
sigma   4.76114350   4.9816850   5.10326000   5.2300450   5.51500975
";

# ╔═╡ f5452c6c-4f33-413c-bb0a-b7263a9bf885
ess, R̂ = ess_rhat(stack_posterior_matrices(results))

# ╔═╡ bee36a7c-2875-4444-b006-6b3f7cb0e4af
summarize_tree_statistics(mapreduce(x -> x.tree_statistics, vcat, results))

# ╔═╡ b78ca7f5-de0e-44af-af75-187d79773a93
md" ##### End of m4.5d.jl."

# ╔═╡ Cell order:
# ╟─6858334e-3f06-4c24-97d6-eced685d2078
# ╠═0ddee595-577c-412c-b14d-e37e8631b84e
# ╠═b1d75537-f57f-449f-bf1a-f45893d681e7
# ╠═8579cdbb-c00e-4ec0-9dd2-3bd49e0c2dc5
# ╠═2aeee6e5-5f5a-4dc1-a74e-e99681598b5b
# ╠═ac08a63f-2a11-4987-804a-2f43dd9f9528
# ╟─a9633f6f-6d03-4e9e-92aa-e4a7a4588671
# ╠═0de0bacf-f5cf-4d32-b4c1-1db120646046
# ╟─8c3d5446-fef0-4c22-b19a-0485d3739e77
# ╠═413f98e4-cfc3-4c65-8885-4bc3cad88224
# ╠═24fd2a28-479d-4973-91f7-714d5c6c4845
# ╠═61609bf1-ca44-4446-8852-7ade37688a6e
# ╠═d3b3fdb1-8bb0-4aae-8af2-2f516bf926fe
# ╠═6357f5ff-5f9d-41df-b769-29873c7dca7c
# ╠═0c5ec62a-3ab8-4062-a98d-b27f57344828
# ╠═80c789d5-94f6-4292-bd45-baf350f3f252
# ╠═bd3f658b-86d8-44f9-b45f-191b9e02a01e
# ╠═428a76c5-87e5-4e90-9e7a-0bd67b43f059
# ╠═27fa1b35-c446-4ba8-9bc5-23380184aca2
# ╠═e87631a3-b41e-4abe-a5e9-b7b9814d89af
# ╠═7c20c076-95f1-47b6-934a-034cb4eb12b7
# ╠═b5a362b7-e51b-4f40-97b0-755976c4dde0
# ╠═f5452c6c-4f33-413c-bb0a-b7263a9bf885
# ╠═bee36a7c-2875-4444-b006-6b3f7cb0e4af
# ╟─b78ca7f5-de0e-44af-af75-187d79773a93
