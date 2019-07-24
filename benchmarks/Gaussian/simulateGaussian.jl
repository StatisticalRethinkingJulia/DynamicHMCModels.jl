using Distributions, Random

function GaussianGen(;μ=0,σ=1,Nd,kwargs...)
 data=(y=rand(Normal(μ,σ),Nd),N=Nd)
   return data
end

