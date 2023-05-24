### A Pluto.jl notebook ###
# v0.19.25

using Markdown
using InteractiveUtils

# ╔═╡ fc1b2162-63ec-4361-b50d-05b0712a2708
using Pkg

# ╔═╡ 8cd67d3f-976a-4133-ab2c-c0daf53c0463
Pkg.activate(expanduser("~/.julia/dev/DynamicHMCModels"))

# ╔═╡ c5fd7c92-a19a-4fb3-a591-762cfd082f06
# # Linear regression

begin
	using DynamicHMCModels
	using RegressionAndOtherStories
end

# ╔═╡ 6f151ccc-50b6-4639-9824-80531c76d304
md" ## StatisticalRethinking m5.3d.jl"

# ╔═╡ 4658d72c-5215-4171-93a3-69a94f47298f
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

# ╔═╡ 8144934d-c35f-40fb-ac7f-4900b5c86760
ProjDir = expanduser("~/.julia/dev/DynamicHMCModels")

# ╔═╡ c1e559dc-cac5-42fc-99c0-e02299019e5b
cd(ProjDir)

# ╔═╡ 7cacfbe6-00e4-4e2b-9121-5c9d32e2b4e2
# Import the dataset.
begin
	df = CSV.read(joinpath(ProjDir, "data", "WaffleDivorce.csv"), DataFrame)
	
	mean_ma = mean(df[:, :Marriage])
	df[!, :Marriage_s] = convert(Vector{Float64},
	  (df[:, :Marriage]) .- mean_ma)/std(df[:, :Marriage]);
	
	mean_mam = mean(df[:, :MedianAgeMarriage])
	df[!, :MedianAgeMarriage_s] = convert(Vector{Float64},
	  (df[:, :MedianAgeMarriage]) .- mean_mam)/std(df[:, :MedianAgeMarriage])
	df
end

# ╔═╡ 6d67d052-25db-4469-b4d8-9ed1ea8d8be5
# Model ``y ∼ Xβ + ϵ``, where ``ϵ ∼ N(0, σ²)`` IID. Student on σ

begin
	mutable struct WaffleDivorce{Ty <: AbstractVector, Tx <: AbstractMatrix}
	    "Observations."
	    y::Ty
	    "Covariates"
	    x::Tx
	end
	
	# Write a function to return a properly dimensioned transformation.
	function make_transformation(model::WaffleDivorce)
	  as((β = as(Array, size(model.x, 2)), σ = asℝ₊))
	end
	
	# Make the type callable with the parameters *as a single argument*.
	function (model::WaffleDivorce)(θ)
	    @unpack y, x = model   # extract the data
	    @unpack β, σ = θ            # works on the named tuple too
	    ll = 0.0
	    ll += logpdf(Normal(10, 10), x[1])
	    ll += logpdf(Normal(0, 1), x[2])
	    ll += logpdf(Normal(0, 1), x[3])
	    ll += logpdf(TDist(1.0), σ)
	    ll += loglikelihood(Normal(0, σ), y .- x*β)
	    ll
	end
end

# ╔═╡ 73edc8b8-a71d-4e1d-befe-fc7110543147
# Instantiate the model with data and inits.
begin
	x = hcat(ones(size(df, 1)), df[:, :Marriage_s], df[:, :MedianAgeMarriage_s]);
	p = WaffleDivorce(df[:, :Divorce], x);
end

# ╔═╡ eac31003-45b1-4178-8b0a-b39791aa8ec8
p((β = [1.0, 2.0, 3.0], σ = 1.0))

# ╔═╡ 01da7f43-687f-4801-9321-5467a8772feb
t = make_transformation(p)

# ╔═╡ f0f3e6dc-c5cb-4973-bc86-a01810a1faa7
P = TransformedLogDensity(t, p)

# ╔═╡ 4169ab2c-913e-4f4e-af65-bb97a41b3e28
∇P = ADgradient(:ForwardDiff, P);

# ╔═╡ 500a08fb-7abd-4715-a52e-ec394ded1d82
results = map(_ -> mcmc_with_warmup(Random.GLOBAL_RNG, ∇P, 1000), 1:4)

# ╔═╡ 07cfe9ba-6e36-4e3b-860f-0b262d0750d8
posterior = TransformVariables.transform.(t, eachcol(pool_posterior_matrices(results)));

# ╔═╡ 85dd96f6-eee9-4d81-840c-a758a47b2502
posterios_σ = round(mean(last, posterior); digits=2)

# ╔═╡ a8ac8770-2e9e-4d72-ba93-745443eeba13
posterios_β = round.(mean(first, posterior); digits=2)

# ╔═╡ 8d5924e0-f5ef-4050-b8b7-91a63ccf04b8
stan_result = "
Iterations = 1:1000
Thinning interval = 1
Chains = 1,2,3,4
Samples per chain = 1000

Empirical Posterior Estimates:
          Mean        SD       Naive SE       MCSE      ESS
    a  9.69137275 0.21507432 0.0034006235 0.0038501180 1000
   bA -1.12184710 0.29039965 0.0045916216 0.0053055477 1000
   bM -0.12106472 0.28705400 0.0045387223 0.0051444688 1000
sigma  1.52326545 0.16272599 0.0025729239 0.0034436330 1000

Quantiles:
         2.5%       25.0%      50.0%      75.0%       97.5%   
    a  9.2694878  9.5497650  9.6906850  9.83227750 10.11643500
   bA -1.6852295 -1.3167700 -1.1254650 -0.92889225 -0.53389157
   bM -0.6889247 -0.3151695 -0.1231065  0.07218513  0.45527243
sigma  1.2421182  1.4125950  1.5107700  1.61579000  1.89891925
";

# ╔═╡ ba51bcd8-2480-4f0e-9bf0-19597058adcf
md" ##### End of m5.3d.jl"

# ╔═╡ Cell order:
# ╟─6f151ccc-50b6-4639-9824-80531c76d304
# ╠═4658d72c-5215-4171-93a3-69a94f47298f
# ╠═fc1b2162-63ec-4361-b50d-05b0712a2708
# ╠═8cd67d3f-976a-4133-ab2c-c0daf53c0463
# ╠═c5fd7c92-a19a-4fb3-a591-762cfd082f06
# ╠═8144934d-c35f-40fb-ac7f-4900b5c86760
# ╠═c1e559dc-cac5-42fc-99c0-e02299019e5b
# ╠═7cacfbe6-00e4-4e2b-9121-5c9d32e2b4e2
# ╠═6d67d052-25db-4469-b4d8-9ed1ea8d8be5
# ╠═73edc8b8-a71d-4e1d-befe-fc7110543147
# ╠═eac31003-45b1-4178-8b0a-b39791aa8ec8
# ╠═01da7f43-687f-4801-9321-5467a8772feb
# ╠═f0f3e6dc-c5cb-4973-bc86-a01810a1faa7
# ╠═4169ab2c-913e-4f4e-af65-bb97a41b3e28
# ╠═500a08fb-7abd-4715-a52e-ec394ded1d82
# ╠═07cfe9ba-6e36-4e3b-860f-0b262d0750d8
# ╠═85dd96f6-eee9-4d81-840c-a758a47b2502
# ╠═a8ac8770-2e9e-4d72-ba93-745443eeba13
# ╠═8d5924e0-f5ef-4050-b8b7-91a63ccf04b8
# ╟─ba51bcd8-2480-4f0e-9bf0-19597058adcf
