using Distributed
addprocs(Sys.CPU_THREADS ÷ 2); # Create children

@everywhere begin # Load on master and all children
using DistributionParameters, ProbabilityDistributions
using LoopVectorization, DynamicHMC, LogDensityProblems, SLEEFPirates, SIMDPirates
using LinearAlgebra, StructuredMatrices, ScatteredArrays, PaddedMatrices
using ProbabilityModels
using DistributionParameters: LKJ_Correlation_Cholesky
using ProbabilityModels: Domains, HierarchicalCentering, ∂HierarchicalCentering, ITPExpectedValue, ∂ITPExpectedValue
BLAS.set_num_threads(1)
end # everywhere

# Define the model on master and all children.
@everywhere @model ITPModel begin

    # Non-hierarchical Priors
    (0.5ρ + 0.5) ~ Beta(2, 2)
    κ ~ Gamma(0.1, 0.1) # μ = 1, σ² = 10
    σ ~ Gamma(1.5, 0.25) # μ = 6, σ² = 2.4
    θ ~ Normal(10)
    L ~ LKJ(2.0)

    # Hierarchical Priors.
    # h subscript, for highest in the hierarhcy.
    μh₁ ~ Normal(10) # μ = 0
    μh₂ ~ Normal(10) # μ = 0
    σh ~ Normal(10) # μ = 0
    # Raw μs; non-cenetered parameterization
    μᵣ₁ ~ Normal() # μ = 0, σ = 1
    μᵣ₂ ~ Normal() # μ = 0, σ = 1
    # Center the μs
    μᵦ₁ = HierarchicalCentering(μᵣ₁, μh₁, σh)
    μᵦ₂ = HierarchicalCentering(μᵣ₂, μh₂, σh)
    σᵦ ~ Normal(10) # μ = 0
    # Raw βs; non-cenetered parameterization
    βᵣ₁ ~ Normal()
    βᵣ₂ ~ Normal()
    # Center the βs.
    β₁ = HierarchicalCentering(βᵣ₁, μᵦ₁, σᵦ, domains)
    β₂ = HierarchicalCentering(βᵣ₂, μᵦ₂, σᵦ, domains)

    U = inv′(Diagonal(σ) * L)

    # Likelihood
    μ₁ = ITPExpectedValue(t, β₁, κ, θ)
    μ₂ = ITPExpectedValue(t, β₂, κ, θ)
    AR = AutoregressiveMatrix(ρ, δh)
    Y₁ ~ Normal(μ₁, AR, U)
    Y₂ ~ Normal(μ₂, AR, U)

end

domains = Domains(2, 2, 2, 3)

K, D = sum(domains), length(domains)

κ = (1/32) * reduce(+, (@Constant randexp(K)) for i ∈ 1:8) # κ ~ Gamma(8, 32)
σd = sum(@Constant randexp(4)) / 16 # σd ~ Gamma(4,16)
θ = 2.0 * (@Constant randn(K)) # θ ~ Normal(0,2)
S = (@Constant randn(K,4K)) |> x -> x * x'
S *= (1/16)
pS = StructuredMatrices.SymmetricMatrixL(S)
L = PaddedMatrices.chol(S); U = PaddedMatrices.invchol(pS)
μh₁, μh₂ = -3.0, 9.0
μᵦ₁ = μh₁ + @Constant randn(D); # placebo
μᵦ₂ = μh₂ + @Constant randn(D); #treatment
β₁ = HierarchicalCentering((@Constant randn(K)), μᵦ₁, σd, domains); # placebo
β₂ = HierarchicalCentering((@Constant randn(K)), μᵦ₂, σd, domains); # treatment

# rand generates uniform(0,1); we take the cumulate sum for the times.
T = 24; δh = (1/16) * reduce(+, (@Constant randexp(T-1)) for i ∈ 1:8)
times = vcat(zero(ConstantFixedSizePaddedVector{1,Float64}), cumsum(δh));

μ₁ = ITPExpectedValue(times, β₁, κ, θ)

μ₂ = ITPExpectedValue(times, β₂, κ, θ)

ρ = 0.7
ARcorrelation = StructuredMatrices.AutoregressiveMatrix(ρ, δh)
ARcholesky = PaddedMatrices.chol(ConstantFixedSizePaddedMatrix(ARcorrelation))
# Create an Array of matrix-normal entries.
Y₁a = [ARcholesky * (@Constant randn(T, K)) * L' + μ₁ for n in 1:120]
Y₂a = [ARcholesky * (@Constant randn(T, K)) * L' + μ₂ for n in 1:120]
Y₁ = ChunkedArray(Y₁a) # Rearranges how the data is stored under the hood.
Y₂ = ChunkedArray(Y₂a) # This often allows for better vectorization.

ℓ_itp = ITPModel(
    domains = domains, Y₁ = Y₁, Y₂ = Y₂, t = times, δh = δh,
    L = LKJ_Correlation_Cholesky{K}, ρ = BoundedFloat{-1,1},
    κ = PositiveVector{K}, θ = RealVector{K},
    μh₁ = RealFloat, μh₂ = RealFloat,
    μᵣ₁ = RealVector{D}, μᵣ₂ = RealVector{D},
    βᵣ₁ = RealVector{K}, βᵣ₂ = RealVector{K},
    σᵦ = PositiveFloat, σh = PositiveFloat,
    σ = PositiveVector{K}
);

@time chains1, tuned_samplers1 = 
  NUTS_init_tune_distributed(ℓ_itp, 2000, δ = 0.75, 
    report = DynamicHMC.ReportSilent());

@time chains2, tuned_samplers2 = 
  NUTS_init_tune_distributed(ℓ_itp, 2000, δ = 0.75,
  report = DynamicHMC.ReportSilent());

using MCMCDiagnostics, Statistics

chains = vcat(chains1, chains2);
tuned_samplers = vcat(tuned_samplers1, tuned_samplers2)
itp_samples = [constrain.(Ref(ℓ_itp), get_position.(chain)) for chain ∈ chains];

μh₁_chains = [[s.μh₁ for s ∈ sample] for sample ∈ itp_samples]
μh₂_chains = [[s.μh₂ for s ∈ sample] for sample ∈ itp_samples]
ρ_chains = [[s.ρ for s ∈ sample] for sample ∈ itp_samples]

poi_chains = (μh₁_chains, μh₂_chains, ρ_chains)

ess = [effective_sample_size(s[i]) for i ∈ eachindex(itp_samples), s ∈ poi_chains]
display(ess[1:end,:])
println()

@show converged = vec(sum(ess, dims = 2)) .> 1000
println()
@show not_converged = .! converged
println()

sum(not_converged) > 0 && @show NUTS_statistics.(chains[not_converged])
sum(not_converged) > 0 && println()
sum(converged) > 0 && @show NUTS_statistics.(chains[converged])
sum(converged) > 0 && println()

poi_chain = [vcat((chains[converged])...) for chains ∈ poi_chains];
@show size(poi_chain)

major_quantiles = [0.05 0.25 0.5 0.75 0.95];
true_values = (μh₁, μh₂, ρ);
for i ∈ eachindex(poi_chain)
    display("Major Quantiles for paramter with true values: $(true_values[i]):")
    display(vcat(major_quantiles, quantile(poi_chain[i], major_quantiles)))
end

ProjDir = @__DIR__
cd(ProjDir) do

  #include("stan_itp.jl")
  #include("analyze_cmdstan.jl")

end