### A Pluto.jl notebook ###
# v0.19.24

using Markdown
using InteractiveUtils

# ╔═╡ 3d3168f7-76c6-4efc-b4ba-a3a309ba1107
using Pkg

# ╔═╡ 38ff4369-752e-4347-b3c6-d7f6accecf64
Pkg.activate(expanduser("~/.julia/dev/DynamicHMCModels"))

# ╔═╡ 3907fbc9-9c8e-4e34-872f-c789685db0b8
begin
	using DynamicHMCModels
	using BenchmarkTools
	using RegressionAndOtherStories
end

# ╔═╡ f03f9724-cff3-4e3b-a1af-c6c6d4e194e8
md" ## Estimate Bernoulli draws probabilility"

# ╔═╡ f7612453-eb1e-434b-b1a6-0bd3dd75a639
html"""
<style>
	main {
		margin: 0 auto;
		max-width: 3500px;
    	padding-left: max(10px, 5%);
    	padding-right: max(10px, 30%);
	}
</style>
"""

# ╔═╡ d58ce0ea-295a-4042-b9ec-4fa46c39d55d
# We estimate a simple model of ``n`` independent Bernoulli draws, with
# probability ``α``. First, we load the packages we use.

# Then define a structure to hold the data.
# For this model, the number of draws equal to `1` is a sufficient statistic.

begin
	"""
	Toy problem using a Bernoulli distribution.
	We model `n` independent draws from a ``Bernoulli(α)`` distribution.
	"""
	struct BernoulliProblem
	    "Total number of draws in the data."
	    n::Int
	    "Number of draws `==1` in the data"
	    s::Int
	end

	# Then make the type callable with the parameters *as a single argument*.  We
	# use decomposition in the arguments, but it could be done inside the function,
	# too.
	
	function (problem::BernoulliProblem)(θ)
	    @unpack α = θ               # extract the parameters
	    @unpack n, s = problem      # extract the data
	    ## log likelihood: the constant log(combinations(n, s)) term
	    ## has been dropped since it is irrelevant for posterior sampling.
	    s * log(α) + (n-s) * log(1-α)
	end
end

# ╔═╡ 51de253c-644a-4472-bf66-e0af573cbfe9
# We should test this, also, this would be a good place to benchmark and
# optimize more complicated problems.

begin
	p = BernoulliProblem(20, 10)
	p((α = 0.5, ))
end

# ╔═╡ 8e35478e-65bd-4113-8ecc-21d28e776719
md"
Recall that we need to

1. transform from ``ℝ`` to the valid parameter domain `(0,1)` for more efficient sampling, and

2. calculate the derivatives for this transformed mapping.

The helper packages `TransformVariables` and `LogDensityProblems` take care of this. We use a flat prior.
"

# ╔═╡ bfb76c06-4036-4539-8c5c-ea86b34aa3d7
md"
!!! note

𝕀 can be typed by \bbi <tab>.

`as𝕀` and `as_unit_interval` are equivalent alternatives.
"

# ╔═╡ 5cdd6541-9b1a-447d-b578-a9a1ff9e724a
t = as((α = as𝕀,))

# ╔═╡ 1ef9579e-1226-4598-91ac-e52f00d96bde
P = TransformedLogDensity(t, p)

# ╔═╡ b1a6c594-b8ca-486c-b564-65ac84f8de95
∇P = ADgradient(:ForwardDiff, P)

# ╔═╡ 2b0c84e7-15b6-4b20-85f5-2d8cfc55dee4
md" ##### Finally, we sample from the posterior. The returned value contains the posterior matrix, diagnostic information, and the tuned sampler which would allow continuation of sampling."

# ╔═╡ faf27168-3392-4d28-b6ed-fb057757642f
results = [mcmc_with_warmup(Random.default_rng(), ∇P, 1000) for _ in 1:5]

# ╔═╡ 6a0894a5-7c2e-4338-ae52-d872fab8e2b3
md" ##### To get the posterior for ``α``, we need to use the columns of the `posterior_matrix` and then transform."

# ╔═╡ ca88f7f4-07ca-4919-8f6d-5ff87c31bdf6
posterior = TransformVariables.transform.(t, eachcol(pool_posterior_matrices(results)))

# ╔═╡ 533060d2-2e0e-4ace-92da-6cdc6ad52628
md" ##### Extract the parameter."

# ╔═╡ 19e5da22-4896-4b0b-a12f-cfa360e33590
posterior_α = first.(posterior);

# ╔═╡ c377e120-94ae-4d43-9f9d-543192ba4578
md" ##### Check the mean/"

# ╔═╡ 09e1ac0c-cb36-42a1-9f62-bd0de0dd61c5
mean(posterior_α)

# ╔═╡ d311dc6a-610c-498a-94b4-c5564583987d
md" ##### Check the effective sample size."

# ╔═╡ d30b2255-a363-4f68-a85b-ce15908b7881
ess, R̂ = ess_rhat(stack_posterior_matrices(results))

# ╔═╡ 185c1a95-3ce9-4c81-9896-76b66e23269b
md" ##### NUTS-specific statistics of the first chain."

# ╔═╡ ce7c47a5-bab0-4703-b5ab-5cb0e8ffd482
summarize_tree_statistics(results[1].tree_statistics)

# ╔═╡ Cell order:
# ╟─f03f9724-cff3-4e3b-a1af-c6c6d4e194e8
# ╠═f7612453-eb1e-434b-b1a6-0bd3dd75a639
# ╠═3d3168f7-76c6-4efc-b4ba-a3a309ba1107
# ╠═38ff4369-752e-4347-b3c6-d7f6accecf64
# ╠═3907fbc9-9c8e-4e34-872f-c789685db0b8
# ╠═d58ce0ea-295a-4042-b9ec-4fa46c39d55d
# ╠═51de253c-644a-4472-bf66-e0af573cbfe9
# ╟─8e35478e-65bd-4113-8ecc-21d28e776719
# ╟─bfb76c06-4036-4539-8c5c-ea86b34aa3d7
# ╠═5cdd6541-9b1a-447d-b578-a9a1ff9e724a
# ╠═1ef9579e-1226-4598-91ac-e52f00d96bde
# ╠═b1a6c594-b8ca-486c-b564-65ac84f8de95
# ╟─2b0c84e7-15b6-4b20-85f5-2d8cfc55dee4
# ╠═faf27168-3392-4d28-b6ed-fb057757642f
# ╟─6a0894a5-7c2e-4338-ae52-d872fab8e2b3
# ╠═ca88f7f4-07ca-4919-8f6d-5ff87c31bdf6
# ╟─533060d2-2e0e-4ace-92da-6cdc6ad52628
# ╠═19e5da22-4896-4b0b-a12f-cfa360e33590
# ╟─c377e120-94ae-4d43-9f9d-543192ba4578
# ╠═09e1ac0c-cb36-42a1-9f62-bd0de0dd61c5
# ╟─d311dc6a-610c-498a-94b4-c5564583987d
# ╠═d30b2255-a363-4f68-a85b-ce15908b7881
# ╟─185c1a95-3ce9-4c81-9896-76b66e23269b
# ╠═ce7c47a5-bab0-4703-b5ab-5cb0e8ffd482
