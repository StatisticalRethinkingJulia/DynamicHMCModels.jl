using Soss

hello = @model x begin
  μ ~ Normal(1, 1)
  σ ~ HalfFlat()
  x ~ Normal(μ, σ) |> iid
end

data = (x=rand(Normal(1, 2), 5),)

nuts(hello, data=data).samples
