ProjDir = @__DIR__
cd(ProjDir)

tuned_samplers = vcat(tuned_samplers1, tuned_samplers2)
itp_samples = [constrain.(Ref(ℓ_itp), get_position.(chain)) for chain ∈ chains];

using MCMCDiagnostics

μh₁_chains = [[s.μh₁ for s ∈ sample] for sample ∈ itp_samples]
μh₂_chains = [[s.μh₂ for s ∈ sample] for sample ∈ itp_samples]
ρ_chains = [[s.ρ for s ∈ sample] for sample ∈ itp_samples]

poi_chains = (μh₁_chains, μh₂_chains, ρ_chains)

ess = [effective_sample_size(s[i]) for i ∈ eachindex(itp_samples), s ∈ poi_chains]
ess |> display

println()
converged = vec(sum(ess, dims = 2)) .> 1000
not_converged = .! converged
NUTS_statistics.(chains[not_converged])

println()
NUTS_statistics.((chains[converged])[1:3])
println()
NUTS_statistics.((chains[converged]))
println()

tuned_samplers[not_converged]
println()
tuned_samplers[converged][1:3]
println()

poi_chain = [vcat((chains[converged])...) for chains ∈ poi_chains]
println()

using Statistics

major_quantiles = [0.05 0.25 0.5 0.75 0.95]

true_values = (μh₁, μh₂, ρ)

for i ∈ eachindex(poi_chain)
    display("Major Quantiles for paramter with true values: $(true_values[i]):")
    display(vcat(major_quantiles, quantile(poi_chain[i], major_quantiles)))
end
