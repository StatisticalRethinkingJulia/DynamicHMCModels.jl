using Soss, Parameters, Distributions
import Distributions: logpdf

mutable struct mydist{T1,T2} <: ContinuousUnivariateDistribution
    μ::T1
    σ::T2
end

function logpdf(dist::mydist,data::Array{Float64,1})
    @unpack μ,σ=dist
    
    LL = 0.0
    for d in data
        LL += logpdf(Normal(μ,σ),d)
    end
    isnan(LL) ? (return Inf) : (return LL) #not as robust as I thought
    #loglikelihood(Normal(μ, σ), data)
    LL
end

linReg1D = @model y begin
  μ ~ Normal(0,1)
  σ ~ Truncated(Cauchy(0,1),0,Inf)
  y ~ Normal(μ,σ) |> iid
end

data = (μ = 0.2, y = rand(Normal(0, 1),10))
data = (y = rand(Normal(0, 1),10),)

nuts(linReg1D, data=data).samples
