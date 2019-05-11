using Soss

hello = Soss.@model μ,x begin
  σ ~ HalfCauchy()
  x ~ Normal(μ, σ) |> iid
end
              
data = (μ=1, x=[2,4,5])

nuts(hello, data=data).samples
