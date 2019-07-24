using Distributions, Random

function simulateSDT(;d=2.,c=0.,Nd,kwargs...)
    θhit=cdf(Normal(0,1),d/2-c)
    θfa=cdf(Normal(0,1),-d/2-c)
    hits = rand(Binomial(Nd,θhit))
    fas = rand(Binomial(Nd,θfa))
      return (hits=hits,fas=fas,Nd=Nd)
 end
