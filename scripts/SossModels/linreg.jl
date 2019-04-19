using Soss

linReg1D = @model N begin
    # Priors chosen following Gelman(2008)
    α ~ Cauchy(0,10)
    β ~ Cauchy(0,2.5)
    σ ~ Truncated(Cauchy(0,3), 0, Inf)
    x ~ For(1:N) do n 
        Cauchy(0,100)
    end
    ŷ = α + β .* x
    y ~ For(1:N) do n 
        Normal(ŷ[n], σ)
    end
end

data = (N=8, )

nuts(linReg1D, data=data).samples
