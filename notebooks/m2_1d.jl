### A Pluto.jl notebook ###
# v0.19.24

using Markdown
using InteractiveUtils

# ╔═╡ d9073ce1-b770-4bc8-b0c9-61c5600b6576
using Pkg

# ╔═╡ eca4fd61-9e23-49d4-92b4-7f3d66afc208
Pkg.activate(expanduser("~/.julia/dev/DynamicHMCModels"))

# ╔═╡ efd842c3-2249-42f7-94a2-6d2c0c501102
# # Estimate Binomial draw probabilility

using DynamicHMCModels

# ╔═╡ 3ba50f6a-d047-465b-92fd-d977ac1055d1
md" ## StatisticalRethinking model `m2.1d`"

# ╔═╡ afda9d87-70d8-45c3-86a7-9e81bf433026
html"""
<style>
	main {
		margin: 0 auto;
		max-width: 3500px;
    	padding-left: max(5px, 5%);
    	padding-right: max(5px, 30%);
	}
</style>
"""

# ╔═╡ f4acdcbc-fefc-421f-bbe9-2e0c39282229
Random.seed!(1356779)

# ╔═╡ 6bb507e4-2999-4d71-8c8f-cd6dff8203ec
begin
	struct BernoulliProblem
	    "Total number of draws in the data."
	    n::Int
	    "Observations"
	    obs::Vector{Int}
	end

	# Add data
	
	
	# Make the type callable with the parameters *as a single argument*. 
	
	function (problem::BernoulliProblem)(θ)
	    @unpack n, obs = problem        # extract the data
	    @unpack p = θ
	    loglikelihood(Binomial(n, p), obs)
	end
end

# ╔═╡ 2b4e5d5c-3cef-459c-b4cb-d2a42394a780
θ = (n = 9, obs = rand(Binomial(9, 2/3), 3))

# ╔═╡ 814bd7b4-2ea4-4b18-80d9-a5dad0c3d408
θ.obs

# ╔═╡ c0584575-c85e-46bb-bd9b-a0bf9b3b00cd
p = BernoulliProblem(θ.n, θ.obs)

# ╔═╡ 14077de1-0794-48a7-a99d-1c895353acf8
p((p = 0.5,))

# ╔═╡ d49ed813-6435-4d16-b0e1-534425ad2e91
t = as((p = as𝕀,))

# ╔═╡ adb30652-feca-4447-a9e3-5e67d9940240
# Use a flat priors (the default, omitted) for α

P = TransformedLogDensity(t, p)

# ╔═╡ c1d4dc80-6aa6-4c7e-82cf-a00cfdc861b1
∇P = ADgradient(:ForwardDiff, P);

# ╔═╡ 903f6acd-8301-4d78-831e-aad350775662
md" ##### Sample chain."

# ╔═╡ 45f77656-eae2-4b26-9f4f-ab8cb04b5b49
results = [mcmc_with_warmup(Random.GLOBAL_RNG, ∇P, 1000; reporter = NoProgressReport()) for _ in 1:4]

# ╔═╡ b5da263f-ff4a-4a13-8566-b92436497813
posterior = TransformVariables.transform.(t, eachcol(pool_posterior_matrices(results)))

# ╔═╡ 9b07615c-d7cb-4bf5-86da-f3e6aabd3902
posterior_p = first.(posterior)

# ╔═╡ dab6f092-66c0-4f8d-afc6-23a01d1c01dd
mean(posterior_p)

# ╔═╡ 8e54b9ec-314d-484b-827d-b5e785eee901
ess, R̂ = ess_rhat(stack_posterior_matrices(results))

# ╔═╡ 3bdaa02b-e8cc-4020-97e7-aab6880c9cff
summarize_tree_statistics(results[1].tree_statistics)

# ╔═╡ Cell order:
# ╟─3ba50f6a-d047-465b-92fd-d977ac1055d1
# ╠═afda9d87-70d8-45c3-86a7-9e81bf433026
# ╠═d9073ce1-b770-4bc8-b0c9-61c5600b6576
# ╠═eca4fd61-9e23-49d4-92b4-7f3d66afc208
# ╠═efd842c3-2249-42f7-94a2-6d2c0c501102
# ╠═f4acdcbc-fefc-421f-bbe9-2e0c39282229
# ╠═6bb507e4-2999-4d71-8c8f-cd6dff8203ec
# ╠═2b4e5d5c-3cef-459c-b4cb-d2a42394a780
# ╠═814bd7b4-2ea4-4b18-80d9-a5dad0c3d408
# ╠═c0584575-c85e-46bb-bd9b-a0bf9b3b00cd
# ╠═14077de1-0794-48a7-a99d-1c895353acf8
# ╠═d49ed813-6435-4d16-b0e1-534425ad2e91
# ╠═adb30652-feca-4447-a9e3-5e67d9940240
# ╠═c1d4dc80-6aa6-4c7e-82cf-a00cfdc861b1
# ╟─903f6acd-8301-4d78-831e-aad350775662
# ╠═45f77656-eae2-4b26-9f4f-ab8cb04b5b49
# ╠═b5da263f-ff4a-4a13-8566-b92436497813
# ╠═9b07615c-d7cb-4bf5-86da-f3e6aabd3902
# ╠═dab6f092-66c0-4f8d-afc6-23a01d1c01dd
# ╠═8e54b9ec-314d-484b-827d-b5e785eee901
# ╠═3bdaa02b-e8cc-4020-97e7-aab6880c9cff
