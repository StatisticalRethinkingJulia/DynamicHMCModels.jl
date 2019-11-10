using DynamicHMCModels, MCMCChains, Random

#Random.seed!(1233)

ProjDir = @__DIR__
cd(ProjDir)

include(joinpath(@__DIR__, "../Benchmarks/LBA/LBA_functions.jl"))

Base.@kwdef struct LBAModel{T}
   data::T
   N::Int
   Nc::Int
end

function make_transformation(model::LBAModel)
    as((v=as(Array,asℝ₊,Nc), A=asℝ₊, k=asℝ₊, tau=asℝ₊))
end

for i = 1:3
  N = 10
  v = [1.0, 1.5]
  Nc = length(v)
  data=simulateLBA(;Nd=N,v=v,A=.8,k=.2,tau=.4)  

  model = LBAModel(; data=data, N=N, Nc=Nc)

  function (model::LBAModel)(θ)
      @unpack data=model
      @unpack v,A,k,tau=θ
      d=LBA(ν=v,A=A,k=k,τ=tau)
      minRT = minimum(x->x[2],data)
      logpdf(d,data)+sum(logpdf.(TruncatedNormal(0,3,0,Inf),v)) +
      logpdf(TruncatedNormal(.8,.4,0,Inf),A)+logpdf(TruncatedNormal(.2,.3,0,Inf),k)+
      logpdf(TruncatedNormal(.4,.1,0,minRT),tau)
  end

  d = [(c,r) for (c,r) in zip(data.choice,data.rt)]

  p = LBAModel(d,N,Nc)
  A = rand(Normal(.8, 1.0), 1)[1]
  k = rand(Normal(.2, 1.0), 1)[1]
  tau = rand(Normal(.4, 1.0), 1)[1]
  v=rand(Normal(0.0, 1.0),Nc)
  p((v=v,A=A,k=k,tau=tau))
  display(d)

end