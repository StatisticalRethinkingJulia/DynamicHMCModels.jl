using DynamicHMCModels, StatsFuns

ProjDir = @__DIR__

delim = ';'
df = CSV.read(joinpath(ProjDir, "..", "..", "data", "chimpanzees.csv"), DataFrame; delim)

Base.@kwdef struct Chimpanzees_02
    "Number of actors"
    N_actors::Int
    pulled_left::Vector{Int}
    prosoc_left::Vector{Int}
    condition::Vector{Int}
    actor::Vector{Int}
end

function make_transformation(model::Chimpanzees_02)
    as((a = as(Vector, model.N_actors), bp = asℝ, bpC = asℝ))
end

model = Chimpanzees_02(; N_actors = maximum(df.actor), pulled_left = df.pulled_left,
                    prosoc_left = df.prosoc_left, condition = df.condition,
                    actor = df.actor)

function (model::Chimpanzees_02)(θ)
    @unpack pulled_left, prosoc_left, condition, actor = model
    @unpack a, bp, bpC = θ
    ℓ_likelihood = mapreduce(+, actor, condition, prosoc_left,
       pulled_left) do actor, condition, prosoc_left, pulled_left
           p = logistic(a[actor] + (bp + bpC * condition) * prosoc_left)
           logpdf(Bernoulli(p), pulled_left)
       end
    P = Normal(0, 10)
    ℓ_prior = logpdf(P, bpC) + logpdf(P, bp) + sum(a -> logpdf(P, a), a)
    ℓ_prior + ℓ_likelihood
end

P = TransformedLogDensity(make_transformation(model), model)
∇P = ADgradient(:ForwardDiff, P)
results = mcmc_with_warmup(Random.GLOBAL_RNG, ∇P, 1000)
posterior = P.transformation.(results.chain)

p = as_particles(posterior)
display(p)

# Result rethinking

rethinking = "
Iterations = 1:1000
Thinning interval = 1
Chains = 1,2,3,4
Samples per chain = 1000

Empirical Posterior Estimates:
        Mean        SD       Naive SE       MCSE      ESS
a.1 -0.74503184 0.26613979 0.0042080396 0.0060183398 1000
a.2 10.77955494 5.32538998 0.0842018089 0.1269148045 1000
a.3 -1.04982353 0.28535997 0.0045119373 0.0049074219 1000
a.4 -1.04898135 0.28129307 0.0044476339 0.0056325117 1000
a.5 -0.74390933 0.26949936 0.0042611590 0.0052178124 1000
a.6  0.21599365 0.26307574 0.0041595927 0.0045153523 1000
a.7  1.81090866 0.39318577 0.0062168129 0.0071483527 1000
 bp  0.83979926 0.26284676 0.0041559722 0.0059795826 1000
bpC -0.12913322 0.29935741 0.0047332562 0.0049519863 1000
";
