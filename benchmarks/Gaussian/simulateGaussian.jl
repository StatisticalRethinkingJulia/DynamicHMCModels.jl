using Distributions, Random

function simulateGaussian(;μ=0, σ=1, Nd, kwargs...)
 (y = rand(Normal(μ,σ), Nd), N = Nd)
end

