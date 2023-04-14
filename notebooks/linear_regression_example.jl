### A Pluto.jl notebook ###
# v0.19.24

using Markdown
using InteractiveUtils

# ╔═╡ c0452572-c9ba-4833-b22a-49c0889b16b2
using Pkg

# ╔═╡ a8c916a9-d464-4fe2-9b6b-ab61308bffed
Pkg.activate(expanduser("~/.julia/dev/DynamicHMCModels"))

# ╔═╡ e5a5c94e-402c-48a8-b573-5b5c877dba69
begin
	using DynamicHMCModels
	using BenchmarkTools
	using RegressionAndOtherStories
end

# ╔═╡ c565bfd9-b5d2-4e50-9527-c8df52579858
md" ## Linear regression"

# ╔═╡ 2cf37bf9-9412-42cf-a524-0041581b48f9
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

# ╔═╡ c897fe4c-4d26-40d0-9338-48022c7044bd
md" ### Estimate simple linear regression model with a half-T prior."

# ╔═╡ b9e2f55a-f809-4467-b617-b292e12b55c3
begin
	# A structure to hold the data: observables, covariates, and the degrees of freedom for the prior.

	"""
	Linear regression model ``y ∼ Xβ + ϵ``, where ``ϵ ∼ N(0, σ²)`` IID.
	Weakly informative prior for `β`, half-T for `σ`.
	"""
	struct LinearRegressionProblem{TY <: AbstractVector, TX <: AbstractMatrix, Tν <: Real}
	    "Observations."
	    y::TY
	    "Covariates"
	    X::TX
	    "Degrees of freedom for prior."
	    ν::Tν
	end
	
	# Make the type callable with the parameters *as a single argument*.

	function (problem::LinearRegressionProblem)(θ)
	    @unpack y, X, ν = problem                    # extract the data
	    @unpack β, σ = θ                             # works on the named tuple too
	    ϵ_distribution = Normal(0, σ)                # the error term
		                                             # likelihood for error
	    ℓ_error = mapreduce((y, x) -> logpdf(ϵ_distribution, y - dot(x, β)), +, y, eachrow(X)) 
	    ℓ_σ = logpdf(TDist(ν), σ)                    # prior for σ
	    ℓ_β = loglikelihood(Normal(0, 10), β)        # prior for β
	    ℓ_error + ℓ_σ + ℓ_β
	end
end

# ╔═╡ 52bcf291-bae0-484d-83ac-2b72487584c9
# Make up random data and test the function runs.

begin
	N = 100
	X = hcat(ones(N), randn(N, 2));
	β = [1.0, 2.0, -1.0]
	σ = 0.5
	y = X*β .+ randn(N) .* σ;
	p = LinearRegressionProblem(y, X, 1.0);
	p((β = β, σ = σ))
end

# ╔═╡ 404098e3-543c-492e-8bff-0ac0c770dd3e
md" ##### It is usually a good idea to benchmark and optimize your log posterior code at this stage. Above, we have carefully optimized allocations away using `mapreduce`."

# ╔═╡ c3294c81-72a3-4435-8019-b0285ad33f6d
@btime p((β = $β, σ = $σ))

# ╔═╡ 21f09380-9554-47b3-b8b8-d04b6fc7260e
md" ##### For this problem, we write a function to return the transformation (as it varies with the number of covariates)."

# ╔═╡ 14d716cb-6c14-45c0-8ef3-0065b2076b57
function problem_transformation(p::LinearRegressionProblem)
    as((β = as(Array, size(p.X, 2)), σ = asℝ₊))
end

# ╔═╡ 731bd8af-0007-44e0-9303-ba38df784fbd
# Wrap the problem with a transformation, then use ForwardDiff for the gradient.

begin
	t = problem_transformation(p)
	P = TransformedLogDensity(t, p)
	∇P = ADgradient(:ForwardDiff, P);
end

# ╔═╡ ce7f9c63-6f71-480b-ad5b-95dae7f08dac
md" ##### Finally, we sample from the posterior. `chain` holds the chain (positions and diagnostic information), while the second returned value is the tuned sampler which would allow continuation of sampling."

# ╔═╡ 3b727805-8d0a-4d72-8b8c-7135095e1ff5
results = map(_ -> mcmc_with_warmup(Random.default_rng(), ∇P, 1000), 1:5)

# ╔═╡ 83bef086-3538-4ae8-ac10-778fb1d0ce30
md" ##### We use the transformation to obtain the posterior from the chain."

# ╔═╡ 0d3a5d33-e49f-4a41-b190-a44ca915a1a4
posterior = TransformVariables.transform.(t, eachcol(pool_posterior_matrices(results)))

# ╔═╡ 7a8ec9c6-2f00-450c-8d5a-2754f8e443d9
md" ##### Extract the parameter posterior means: `β`."

# ╔═╡ 11d815b2-8375-4229-970e-f66187b4d014
posterior_β = mean(first, posterior)

# ╔═╡ 4c790100-a9c9-452b-9e6a-6d9147a8d807
md" ##### then `σ`:"

# ╔═╡ bfd42f7a-6d73-45cc-8112-c44749c2c1e7
posterior_σ = mean(last, posterior)

# ╔═╡ fee2b723-23b7-45d3-add4-6657396a389b
md" ##### Effective sample sizes (of untransformed draws)"

# ╔═╡ 2eeecb48-f659-4a26-89b1-0b16d64450ec
ess, R̂ = ess_rhat(stack_posterior_matrices(results))

# ╔═╡ e3c07642-86f0-4d5c-b9e3-dc4f59731604
md" ##### summarize NUTS-specific statistics of all chains"

# ╔═╡ 2580659d-1186-481b-a1e7-d0f21cf08d94
summarize_tree_statistics(mapreduce(x -> x.tree_statistics, vcat, results))

# ╔═╡ Cell order:
# ╟─c565bfd9-b5d2-4e50-9527-c8df52579858
# ╠═2cf37bf9-9412-42cf-a524-0041581b48f9
# ╠═c0452572-c9ba-4833-b22a-49c0889b16b2
# ╠═a8c916a9-d464-4fe2-9b6b-ab61308bffed
# ╟─c897fe4c-4d26-40d0-9338-48022c7044bd
# ╠═e5a5c94e-402c-48a8-b573-5b5c877dba69
# ╠═b9e2f55a-f809-4467-b617-b292e12b55c3
# ╠═52bcf291-bae0-484d-83ac-2b72487584c9
# ╟─404098e3-543c-492e-8bff-0ac0c770dd3e
# ╠═c3294c81-72a3-4435-8019-b0285ad33f6d
# ╟─21f09380-9554-47b3-b8b8-d04b6fc7260e
# ╠═14d716cb-6c14-45c0-8ef3-0065b2076b57
# ╠═731bd8af-0007-44e0-9303-ba38df784fbd
# ╟─ce7f9c63-6f71-480b-ad5b-95dae7f08dac
# ╠═3b727805-8d0a-4d72-8b8c-7135095e1ff5
# ╟─83bef086-3538-4ae8-ac10-778fb1d0ce30
# ╠═0d3a5d33-e49f-4a41-b190-a44ca915a1a4
# ╟─7a8ec9c6-2f00-450c-8d5a-2754f8e443d9
# ╠═11d815b2-8375-4229-970e-f66187b4d014
# ╟─4c790100-a9c9-452b-9e6a-6d9147a8d807
# ╠═bfd42f7a-6d73-45cc-8112-c44749c2c1e7
# ╟─fee2b723-23b7-45d3-add4-6657396a389b
# ╠═2eeecb48-f659-4a26-89b1-0b16d64450ec
# ╟─e3c07642-86f0-4d5c-b9e3-dc4f59731604
# ╠═2580659d-1186-481b-a1e7-d0f21cf08d94
