### A Pluto.jl notebook ###
# v0.19.25

using Markdown
using InteractiveUtils

# ╔═╡ bcea290f-8f44-41a2-a187-511d9dea69e4
using Pkg

# ╔═╡ 24f81b20-4fb6-44b1-b46e-66e688a2c8ad
Pkg.activate(expanduser("~/.julia/dev/DynamicHMCModels"))

# ╔═╡ cdf7a1e4-4000-4df7-bdf8-0a288e67890c
begin
	using DynamicHMCModels
	using BenchmarkTools
	using RegressionAndOtherStories
end

# ╔═╡ 474de18f-ddd6-4706-9350-1e1f57c49a88
md" ## Statistical Rethinking m4.1d"

# ╔═╡ dc8ff75e-0595-49dc-932e-f5def2628b65
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

# ╔═╡ 2b7daaf6-fbbc-4b69-b471-b0e2cd22ca0d
ProjDir = expanduser("~/.julia/dev/DynamicHMCModels")

# ╔═╡ d5003ff0-cea4-443b-9969-f398799c6420
howell1 = CSV.read(joinpath(ProjDir, "data", "Howell1.csv"), DataFrame)

# ╔═╡ 4edc0eaf-2102-4d62-9fd8-372af43f9bfd
md" ##### Use only adults."

# ╔═╡ 01f7ad1e-c224-4bdd-bf21-6c92db56fa1f
df = filter(row -> row[:age] >= 18, howell1);

# ╔═╡ e1dbd47a-1e81-4ce4-b818-790ad6fc34d4
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

# ╔═╡ 37f3be2c-e3b7-4f5c-b6f5-51aa3c9d3cbf
p = Heights(df[:, :height], 1.0)

# ╔═╡ 1a97d42e-71dd-4619-8d32-684f8d19d457
p((μ=150.0, σ=7.7))

# ╔═╡ f5714585-2668-4dad-b4d3-a464728c1e6e
md" ##### Wrap the problem with a transformation, then use ForwardDiff for the gradient."

# ╔═╡ d96fd311-37d1-45ad-a7ea-09e12f3825cd
t = make_transformation(p)

# ╔═╡ 3cc76731-c609-4a99-9b7c-ef76eccd066c
P = TransformedLogDensity(t, p)

# ╔═╡ f9b91f6a-6036-4414-9253-cabfdb9f5e8d
∇P = ADgradient(:ForwardDiff, P);

# ╔═╡ 3615fdc2-7b39-476e-bc63-2b684d04371f
# Tune and sample.

results = map(_ -> mcmc_with_warmup(Random.GLOBAL_RNG, ∇P, 1000), 1:4)

# ╔═╡ 9c13ee2d-9279-4da8-bcb4-843f103fa5ac
posterior = TransformVariables.transform.(t, eachcol(pool_posterior_matrices(results)))

# ╔═╡ 3483cb51-5e6a-45a4-901b-8e3586aa0e7c
posterior_σ = round(mean(first, posterior); digits=2)

# ╔═╡ e1c2f24f-2c5c-4cb5-953e-c2081ebae961
posterior_μ = round(mean(last, posterior); digits=2)

# ╔═╡ 59c39d89-a46f-48de-b50f-8852d1a374a2
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

# ╔═╡ 58eee139-40f0-42e3-a751-5d928fb26a04
ess, R̂ = ess_rhat(stack_posterior_matrices(results))

# ╔═╡ cab7a6cf-e142-4024-b554-330cce7773c3
summarize_tree_statistics(mapreduce(x -> x.tree_statistics, vcat, results))

# ╔═╡ 768ae547-2a06-4be2-8d1e-5b0e80f8b498
md" ##### End of m4.1d.jl."

# ╔═╡ Cell order:
# ╟─474de18f-ddd6-4706-9350-1e1f57c49a88
# ╠═dc8ff75e-0595-49dc-932e-f5def2628b65
# ╠═bcea290f-8f44-41a2-a187-511d9dea69e4
# ╠═2b7daaf6-fbbc-4b69-b471-b0e2cd22ca0d
# ╠═24f81b20-4fb6-44b1-b46e-66e688a2c8ad
# ╠═cdf7a1e4-4000-4df7-bdf8-0a288e67890c
# ╠═d5003ff0-cea4-443b-9969-f398799c6420
# ╟─4edc0eaf-2102-4d62-9fd8-372af43f9bfd
# ╠═01f7ad1e-c224-4bdd-bf21-6c92db56fa1f
# ╠═e1dbd47a-1e81-4ce4-b818-790ad6fc34d4
# ╠═37f3be2c-e3b7-4f5c-b6f5-51aa3c9d3cbf
# ╠═1a97d42e-71dd-4619-8d32-684f8d19d457
# ╟─f5714585-2668-4dad-b4d3-a464728c1e6e
# ╠═d96fd311-37d1-45ad-a7ea-09e12f3825cd
# ╠═3cc76731-c609-4a99-9b7c-ef76eccd066c
# ╠═f9b91f6a-6036-4414-9253-cabfdb9f5e8d
# ╠═3615fdc2-7b39-476e-bc63-2b684d04371f
# ╠═9c13ee2d-9279-4da8-bcb4-843f103fa5ac
# ╠═3483cb51-5e6a-45a4-901b-8e3586aa0e7c
# ╠═e1c2f24f-2c5c-4cb5-953e-c2081ebae961
# ╠═59c39d89-a46f-48de-b50f-8852d1a374a2
# ╠═58eee139-40f0-42e3-a751-5d928fb26a04
# ╠═cab7a6cf-e142-4024-b554-330cce7773c3
# ╟─768ae547-2a06-4be2-8d1e-5b0e80f8b498
