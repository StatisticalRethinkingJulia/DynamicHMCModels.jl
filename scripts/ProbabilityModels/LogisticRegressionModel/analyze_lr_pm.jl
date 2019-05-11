@show tuned_sampler

using MCMCDiagnostics

df = describe(pm_chns)

df[1].df[:ess] = [effective_sample_size(pm[:, i]) for i ∈ 1:size(pm, 2)]
df |> display
println()

