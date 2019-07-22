using Soss

m = Soss.@model N begin
  μ ~ Normal(0, 5)
  σ ~ HalfCauchy(3)
  x ~ Normal(μ, σ) |> iid(N)
end

sourceLogdensity(m)
              
gaussianMixture = @model begin
    N ~ Poisson(100)
    K ~ Poisson(2.5)
    p ~ Dirichlet(K, 1.0)
    μ ~ Normal(0,1.5) |> iid(K)
    σ ~ HalfNormal(1)
    θ = [(m,σ) for m in μ]
    x ~ MixtureModel(Normal, θ, p) |> iid(N)
end

m2 = gaussianMixture(N=100,K=2)

rand(m2) |> pairs

m3 = @model begin
    p ~ Uniform()
    μ ~ Normal(0, 1.5) |> iid(2)
    σ ~ HalfNormal(1)
    θ = [(m, σ) for m in μ]
    x ~ MixtureModel(Normal,θ,[p,1-p]) |> iid(100)
end

m3_fwd = m3(:p,:μ,:σ)

m3_inv = m3(:x)

#post3 = nuts(m3_inv)
	
m4 = @model y begin
    μ ~ Normal(0, 1)
    σ ~ HalfCauchy(1)
    ε ~ TDist(5)
    y ~ Normal(μ + ε, σ)
end
 
#symlogpdf(m4)

data = (x=[2, 4, 5, 4, 4])

#nuts(m4, data=data).samples
