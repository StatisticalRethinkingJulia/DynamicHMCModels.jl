using Distributions, Random

function simulateLR(;Nd = 4, Nc = 1,β0 = 1., β = fill(.5, Nc), σ = 1, kwargs...)
    x = rand(Normal(10,5),Nd,Nc)
    y = β0 .+ x*β .+ rand(Normal(0,σ),Nd)
    return (x=x, y=y, Nd=Nd, Nc=Nc)
 end
