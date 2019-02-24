var documenterSearchIndex = {"docs": [

{
    "location": "intro/#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "intro/#DynamicHMCModels-1",
    "page": "Home",
    "title": "DynamicHMCModels",
    "category": "section",
    "text": "This package contains Julia versions of selected code snippets and mcmc models contained in the R package \"rethinking\" associated with the book Statistical Rethinking by Richard McElreath. The models are implemented using DynamicHMC.jl"
},

{
    "location": "02/m2.1d/#",
    "page": "m2.1d",
    "title": "m2.1d",
    "category": "page",
    "text": "EditURL = \"https://github.com/StatisticalRethinkingJulia/DynamicHMCModels.jl/blob/master/scripts/02/m2.1d.jl\""
},

{
    "location": "02/m2.1d/#Estimate-Binomial-draw-probabilility-1",
    "page": "m2.1d",
    "title": "Estimate Binomial draw probabilility",
    "category": "section",
    "text": "using DynamicHMCModelsDefine a structure to hold the data.struct BernoulliProblem\n    \"Total number of draws in the data.\"\n    n::Int\n    \"Number of draws `==1` in the data\"\n    s::Vector{Int}\nend;Make the type callable with the parameters as a single argument.function (problem::BernoulliProblem)((α, )::NamedTuple{(:α, )})\n    @unpack n, s = problem        # extract the data\n    loglikelihood(Binomial(n, α), s)\nendCreate the data and complete setting up the problem.obs = rand(Binomial(9, 2/3), 1)\np = BernoulliProblem(9, obs)\np((α = 0.5, ))Write a function to return properly dimensioned transformation.problem_transformation(p::BernoulliProblem) =\n    as((α = as𝕀, ),  )Use a flat priors (the default, omitted) for αP = TransformedLogDensity(problem_transformation(p), p)\n∇P = LogDensityRejectErrors(ADgradient(:ForwardDiff, P));Samplechain, NUTS_tuned = NUTS_init_tune_mcmc(∇P, 1000)To get the posterior for α use get_position and then transform back.posterior = TransformVariables.transform.(Ref(problem_transformation(p)), get_position.(chain));Extract the parameter.posterior_α = first.(posterior);check the effective sample sizeess_α = effective_sample_size(posterior_α)NUTS-specific statisticsNUTS_statistics(chain)check the meanmean(posterior_α)This page was generated using Literate.jl."
},

{
    "location": "04/m4.1d/#",
    "page": "m4.1d",
    "title": "m4.1d",
    "category": "page",
    "text": "EditURL = \"https://github.com/StatisticalRethinkingJulia/DynamicHMCModels.jl/blob/master/scripts/04/m4.1d.jl\""
},

{
    "location": "04/m4.1d/#Heights-problem-1",
    "page": "m4.1d",
    "title": "Heights problem",
    "category": "section",
    "text": "We estimate simple linear regression model with a half-T prior.using DynamicHMCModels\n\nProjDir = rel_path_d(\"..\", \"scripts\", \"04\")\ncd(ProjDir)Import the dataset.howell1 = CSV.read(rel_path(\"..\", \"data\", \"Howell1.csv\"), delim=\';\');\ndf = convert(DataFrame, howell1);Use only adults and standardizedf2 = filter(row -> row[:age] >= 18, df);Show the first six rows of the dataset.first(df2, 6)Half-T for σ, see below.struct HeightsProblem{TY <: AbstractVector, Tν <: Real}\n    \"Observations.\"\n    y::TY\n    \"Degrees of freedom for prior on sigma.\"\n    ν::Tν\nend;Then make the type callable with the parameters as a single argument.function (problem::HeightsProblem)(θ)\n    @unpack y, ν = problem   # extract the data\n    @unpack μ, σ = θ\n    loglikelihood(Normal(μ, σ), y) + logpdf(TDist(ν), σ)\nend;Setup problem with data and inits.obs = convert(Vector{Float64}, df2[:height]);\np = HeightsProblem(obs, 1.0);\np((μ = 178, σ = 5.0,))Write a function to return properly dimensioned transformation.problem_transformation(p::HeightsProblem) =\n    as((σ = asℝ₊, μ  = as(Real, 100, 250)), )Wrap the problem with a transformation, then use Flux for the gradient.P = TransformedLogDensity(problem_transformation(p), p)\n∇P = LogDensityRejectErrors(ADgradient(:ForwardDiff, P));Tune and sample.chain, NUTS_tuned = NUTS_init_tune_mcmc(∇P, 1000);We use the transformation to obtain the posterior from the chain.posterior = TransformVariables.transform.(Ref(problem_transformation(p)), get_position.(chain));Extract the parameter posterior means: β,posterior_μ = mean(last, posterior)then σ:posterior_σ = mean(first, posterior)Effective sample sizes (of untransformed draws)ess = mapslices(effective_sample_size,\n                get_position_matrix(chain); dims = 1)NUTS-specific statisticsNUTS_statistics(chain)\n\ncmdstan_result = \"\nIterations = 1:1000\nThinning interval = 1\nChains = 1,2,3,4\nSamples per chain = 1000\n\nEmpirical Posterior Estimates:\n          Mean        SD       Naive SE      MCSE      ESS\nsigma   7.7641872 0.29928194 0.004732063 0.0055677898 1000\n   mu 154.6055177 0.41989355 0.006639100 0.0085038356 1000\n\nQuantiles:\n         2.5%      25.0%       50.0%      75.0%       97.5%\nsigma   7.21853   7.5560625   7.751355   7.9566775   8.410391\n   mu 153.77992 154.3157500 154.602000 154.8820000 155.431000\n\";Extract the parameter posterior means: β,[posterior_μ, posterior_σ]end of m4.5d.jl#- This page was generated using Literate.jl."
},

{
    "location": "04/m4.2d/#",
    "page": "m4.2d",
    "title": "m4.2d",
    "category": "page",
    "text": "EditURL = \"https://github.com/StatisticalRethinkingJulia/DynamicHMCModels.jl/blob/master/scripts/04/m4.2d.jl\""
},

{
    "location": "04/m4.2d/#Heights-problem-with-restricted-prior-on-mu.-1",
    "page": "m4.2d",
    "title": "Heights problem with restricted prior on mu.",
    "category": "section",
    "text": "Result is not conform cmdstan resultusing DynamicHMCModels\n\nProjDir = rel_path_d(\"..\", \"scripts\", \"04\")\ncd(ProjDir)Import the dataset.howell1 = CSV.read(rel_path(\"..\", \"data\", \"Howell1.csv\"), delim=\';\')\ndf = convert(DataFrame, howell1);Use only adults and standardizedf2 = filter(row -> row[:age] >= 18, df);Show the first six rows of the dataset.first(df2, 6)No covariates, just height observations.struct ConstraintHeightsProblem{TY <: AbstractVector}\n    \"Observations.\"\n    y::TY\nend;Very constraint prior on μ. Flat σ.function (problem::ConstraintHeightsProblem)(θ)\n    @unpack y = problem   # extract the data\n    @unpack μ, σ = θ\n    loglikelihood(Normal(μ, σ), y) + logpdf(Normal(178, 0.1), μ) +\n    logpdf(Uniform(0, 50), σ)\nend;Define problem with data and inits.obs = convert(Vector{Float64}, df2[:height])\np = ConstraintHeightsProblem(obs);\np((μ = 178, σ = 5.0))Write a function to return properly dimensioned transformation.problem_transformation(p::ConstraintHeightsProblem) =\n    as((μ  = as(Real, 100, 250), σ = asℝ₊), )Use Flux for the gradient.P = TransformedLogDensity(problem_transformation(p), p)\n∇P = LogDensityRejectErrors(ADgradient(:ForwardDiff, P));FSample from the posterior.chain, NUTS_tuned = NUTS_init_tune_mcmc(∇P, 1000);Undo the transformation to obtain the posterior from the chain.posterior = TransformVariables.transform.(Ref(problem_transformation(p)), get_position.(chain));Extract the parameter posterior means: μ,posterior_μ = mean(first, posterior)Extract the parameter posterior means: μ,posterior_σ = mean(last, posterior)Effective sample sizes (of untransformed draws)ess = mapslices(effective_sample_size,\n                get_position_matrix(chain); dims = 1)NUTS-specific statisticsNUTS_statistics(chain)cmdstan resultcmdstan_result = \"\nIterations = 1:1000\nThinning interval = 1\nChains = 1,2,3,4\nSamples per chain = 1000\n\nEmpirical Posterior Estimates:\n         Mean         SD       Naive SE       MCSE      ESS\nsigma  24.604616 0.946911707 0.0149719887 0.0162406632 1000\n   mu 177.864069 0.102284043 0.0016172527 0.0013514459 1000\n\nQuantiles:\n         2.5%       25.0%     50.0%     75.0%     97.5%\nsigma  22.826377  23.942275  24.56935  25.2294  26.528368\n   mu 177.665000 177.797000 177.86400 177.9310 178.066000\n\";Extract the parameter posterior means: β,[posterior_μ, posterior_σ]end of m4.5d.jl#- This page was generated using Literate.jl."
},

{
    "location": "04/m4.5d/#",
    "page": "m4.5d",
    "title": "m4.5d",
    "category": "page",
    "text": "EditURL = \"https://github.com/StatisticalRethinkingJulia/DynamicHMCModels.jl/blob/master/scripts/04/m4.5d.jl\""
},

{
    "location": "04/m4.5d/#Polynomial-weight-model-model-1",
    "page": "m4.5d",
    "title": "Polynomial weight model model",
    "category": "section",
    "text": "using DynamicHMCModels\n\nProjDir = rel_path_d(\"..\", \"scripts\", \"04\")\ncd(ProjDir)Import the dataset.howell1 = CSV.read(rel_path(\"..\", \"data\", \"Howell1.csv\"), delim=\';\')\ndf = convert(DataFrame, howell1);Use only adults and standardizedf2 = filter(row -> row[:age] >= 18, df);\ndf2[:weight] = convert(Vector{Float64}, df2[:weight]);\ndf2[:weight_s] = (df2[:weight] .- mean(df2[:weight])) / std(df2[:weight]);\ndf2[:weight_s2] = df2[:weight_s] .^ 2;Show the first six rows of the dataset.first(df2, 6)Then define a structure to hold the data: observables, covariates, and the degrees of freedom for the prior.Linear regression model y  Xβ + ϵ, where ϵ  N(0 σ²) IID.struct ConstraintHeightProblem{TY <: AbstractVector, TX <: AbstractMatrix}\n    \"Observations.\"\n    y::TY\n    \"Covariates\"\n    X::TX\nend;Then make the type callable with the parameters as a single argument.function (problem::ConstraintHeightProblem)(θ)\n    @unpack y, X, = problem   # extract the data\n    @unpack β, σ = θ            # works on the named tuple too\n    ll = 0.0\n    ll += logpdf(Normal(178, 100), X[1]) # a = X[1]\n    ll += logpdf(Normal(0, 10), X[2]) # b1 = X[2]\n    ll += logpdf(Normal(0, 10), X[3]) # b2 = X[3]\n    ll += logpdf(TDist(1.0), σ)\n    ll += loglikelihood(Normal(0, σ), y .- X*β)\n    ll\nendSetup data and inits.N = size(df2, 1)\nX = hcat(ones(N), hcat(df2[:weight_s], df2[:weight_s2]));\ny = convert(Vector{Float64}, df2[:height])\np = ConstraintHeightProblem(y, X);\np((β = [1.0, 2.0, 3.0], σ = 1.0))Use a function to return the transformation (as it varies with the number of covariates).problem_transformation(p::ConstraintHeightProblem) =\n    as((β = as(Array, size(p.X, 2)), σ = asℝ₊))Wrap the problem with a transformation, then use Flux for the gradient.P = TransformedLogDensity(problem_transformation(p), p)\n∇P = LogDensityRejectErrors(ADgradient(:ForwardDiff, P));Draw samples.chain, NUTS_tuned = NUTS_init_tune_mcmc(∇P, 1000);We use the transformation to obtain the posterior from the chain.posterior = TransformVariables.transform.(Ref(problem_transformation(p)), get_position.(chain));\nposterior[1:5]Extract the parameter posterior means: β,posterior_β = mean(first, posterior)then σ:posterior_σ = mean(last, posterior)Effective sample sizes (of untransformed draws)ess = mapslices(effective_sample_size,\n                get_position_matrix(chain); dims = 1)NUTS-specific statisticsNUTS_statistics(chain)\n\ncmdstan_result = \"\nIterations = 1:1000\nThinning interval = 1\nChains = 1,2,3,4\nSamples per chain = 1000\n\nEmpirical Posterior Estimates:\n           Mean         SD       Naive SE       MCSE      ESS\n    a 154.609019750 0.36158389 0.0057171433 0.0071845548 1000\n   b1   5.838431778 0.27920926 0.0044146860 0.0048693502 1000\n   b2  -0.009985954 0.22897191 0.0036203637 0.0047224478 1000\nsigma   5.110136300 0.19096315 0.0030193925 0.0030728192 1000\n\nQuantiles:\n          2.5%        25.0%        50.0%       75.0%        97.5%\n    a 153.92392500 154.3567500 154.60700000 154.8502500 155.32100000\n   b1   5.27846200   5.6493250   5.83991000   6.0276275   6.39728200\n   b2  -0.45954687  -0.1668285  -0.01382935   0.1423620   0.43600905\nsigma   4.76114350   4.9816850   5.10326000   5.2300450   5.51500975\n\";Extract the parameter posterior means: β,[posterior_β, posterior_σ]end of m4.5d.jl#- This page was generated using Literate.jl."
},

{
    "location": "05/m5.1d/#",
    "page": "m5.1d",
    "title": "m5.1d",
    "category": "page",
    "text": "EditURL = \"https://github.com/StatisticalRethinkingJulia/DynamicHMCModels.jl/blob/master/scripts/05/m5.1d.jl\""
},

{
    "location": "05/m5.1d/#Linear-regression-1",
    "page": "m5.1d",
    "title": "Linear regression",
    "category": "section",
    "text": "using DynamicHMCModels\n\nProjDir = rel_path_d(\"..\", \"scripts\", \"05\")\ncd(ProjDir)Import the dataset."
},

{
    "location": "05/m5.1d/#snippet-5.1-1",
    "page": "m5.1d",
    "title": "snippet 5.1",
    "category": "section",
    "text": "wd = CSV.read(rel_path(\"..\", \"data\", \"WaffleDivorce.csv\"), delim=\';\')\ndf = convert(DataFrame, wd);\nmean_ma = mean(df[:MedianAgeMarriage])\ndf[:MedianAgeMarriage_s] = convert(Vector{Float64},\n  (df[:MedianAgeMarriage]) .- mean_ma)/std(df[:MedianAgeMarriage]);Show the first six rows of the dataset.first(df, 6)Model y  Normal(y - Xβ σ). Flat prior for β, half-T for σ.struct WaffleDivorceProblem{TY <: AbstractVector, TX <: AbstractMatrix}\n    \"Observations.\"\n    y::TY\n    \"Covariates\"\n    X::TX\nendMake the type callable with the parameters as a single argument.function (problem::WaffleDivorceProblem)(θ)\n    @unpack y, X, = problem   # extract the data\n    @unpack β, σ = θ            # works on the named tuple too\n    ll = 0.0\n    ll += logpdf(Normal(10, 10), X[1]) # a = X[1]\n    ll += logpdf(Normal(0, 1), X[2]) # b1 = X[2]\n    ll += logpdf(TDist(1.0), σ)\n    ll += loglikelihood(Normal(0, σ), y .- X*β)\n    ll\nendInstantiate the model with data and inits.N = size(df, 1)\nX = hcat(ones(N), df[:MedianAgeMarriage_s]);\ny = convert(Vector{Float64}, df[:Divorce])\np = WaffleDivorceProblem(y, X);\np((β = [1.0, 2.0], σ = 1.0))Write a function to return properly dimensioned transformation.problem_transformation(p::WaffleDivorceProblem) =\n    as((β = as(Array, size(p.X, 2)), σ = asℝ₊))Wrap the problem with a transformation, then use Flux for the gradient.P = TransformedLogDensity(problem_transformation(p), p)\n∇P = LogDensityRejectErrors(ADgradient(:ForwardDiff, P));Tune and sample.chain, NUTS_tuned = NUTS_init_tune_mcmc(∇P, 1000);We use the transformation to obtain the posterior from the chain.posterior = TransformVariables.transform.(Ref(problem_transformation(p)), get_position.(chain));\nposterior[1:5]Extract the parameter posterior means: β,posterior_β = mean(first, posterior)then σ:posterior_σ = mean(last, posterior)Effective sample sizes (of untransformed draws)ess = mapslices(effective_sample_size,\n                get_position_matrix(chain); dims = 1)NUTS-specific statisticsNUTS_statistics(chain)cmdstan resultcmdstan_result = \"\nIterations = 1:1000\nThinning interval = 1\nChains = 1,2,3,4\nSamples per chain = 1000\n\nEmpirical Posterior Estimates:\n         Mean        SD       Naive SE       MCSE      ESS\n    a  9.6882466 0.22179190 0.0035068378 0.0031243061 1000\n   bA -1.0361742 0.21650514 0.0034232469 0.0034433245 1000\nsigma  1.5180337 0.15992781 0.0025286807 0.0026279593 1000\n\nQuantiles:\n         2.5%      25.0%     50.0%      75.0%       97.5%\n    a  9.253141  9.5393175  9.689585  9.84221500 10.11121000\n   bA -1.454571 -1.1821025 -1.033065 -0.89366925 -0.61711705\nsigma  1.241496  1.4079225  1.504790  1.61630750  1.86642750\n\";Extract the parameter posterior means: β,[posterior_β[1], posterior_β[2], posterior_σ]end of m4.5d.jl#- This page was generated using Literate.jl."
},

{
    "location": "05/m5.1d1/#",
    "page": "m5.1d1",
    "title": "m5.1d1",
    "category": "page",
    "text": "EditURL = \"https://github.com/StatisticalRethinkingJulia/DynamicHMCModels.jl/blob/master/scripts/05/m5.1d1.jl\""
},

{
    "location": "05/m5.1d1/#Linear-regression-1",
    "page": "m5.1d1",
    "title": "Linear regression",
    "category": "section",
    "text": "using DynamicHMCModels, MCMCChain\n\nProjDir = rel_path_d(\"..\", \"scripts\", \"05\")\ncd(ProjDir)Import the dataset."
},

{
    "location": "05/m5.1d1/#snippet-5.1-1",
    "page": "m5.1d1",
    "title": "snippet 5.1",
    "category": "section",
    "text": "wd = CSV.read(rel_path(\"..\", \"data\", \"WaffleDivorce.csv\"), delim=\';\')\ndf = convert(DataFrame, wd);\nmean_ma = mean(df[:MedianAgeMarriage])\ndf[:MedianAgeMarriage_s] = convert(Vector{Float64},\n  (df[:MedianAgeMarriage]) .- mean_ma)/std(df[:MedianAgeMarriage]);Show the first six rows of the dataset.first(df, 6)Model y  Normal(y - Xβ σ). Flat prior for β, half-T for σ.struct WaffleDivorceProblem{TY <: AbstractVector, TX <: AbstractMatrix}\n    \"Observations.\"\n    y::TY\n    \"Covariates\"\n    X::TX\nendMake the type callable with the parameters as a single argument.function (problem::WaffleDivorceProblem)(θ)\n    @unpack y, X, = problem   # extract the data\n    @unpack β, σ = θ            # works on the named tuple too\n    ll = 0.0\n    ll += logpdf(Normal(10, 10), X[1]) # a = X[1]\n    ll += logpdf(Normal(0, 1), X[2]) # b1 = X[2]\n    ll += logpdf(TDist(1.0), σ)\n    ll += loglikelihood(Normal(0, σ), y .- X*β)\n    ll\nendInstantiate the model with data and inits.N = size(df, 1)\nX = hcat(ones(N), df[:MedianAgeMarriage_s]);\ny = convert(Vector{Float64}, df[:Divorce])\np = WaffleDivorceProblem(y, X);\np((β = [1.0, 2.0], σ = 1.0))Write a function to return properly dimensioned transformation.problem_transformation(p::WaffleDivorceProblem) =\n    as((β = as(Array, size(p.X, 2)), σ = asℝ₊))Wrap the problem with a transformation, then use Flux for the gradient.P = TransformedLogDensity(problem_transformation(p), p)\n∇P = LogDensityRejectErrors(ADgradient(:ForwardDiff, P));Create an array to hold 1000 samples of 3 parameters in 4 chainsa3d = create_a3d(1000, 3, 4);\ntrans = as( (β = as(Array, 2), σ = asℝ));Sample from the 4 chains and store the draws in the a3d arrayfor j in 1:4\n  chain, NUTS_tuned = NUTS_init_tune_mcmc(∇P, 1000);\n  posterior = TransformVariables.transform.(Ref(problem_transformation(p)),\n    get_position.(chain));\n  insert_chain!(a3d, j, posterior, trans)\nendConvert to a MCMCChainchns = create_mcmcchain(a3d, [\"a\", \"bA\", \"σ\"]);cmdstan resultcmdstan_result = \"\nIterations = 1:1000\nThinning interval = 1\nChains = 1,2,3,4\nSamples per chain = 1000\n\nEmpirical Posterior Estimates:\n         Mean        SD       Naive SE       MCSE      ESS\n    a  9.6882466 0.22179190 0.0035068378 0.0031243061 1000\n   bA -1.0361742 0.21650514 0.0034232469 0.0034433245 1000\nsigma  1.5180337 0.15992781 0.0025286807 0.0026279593 1000\n\nQuantiles:\n         2.5%      25.0%     50.0%      75.0%       97.5%\n    a  9.253141  9.5393175  9.689585  9.84221500 10.11121000\n   bA -1.454571 -1.1821025 -1.033065 -0.89366925 -0.61711705\nsigma  1.241496  1.4079225  1.504790  1.61630750  1.86642750\n\";Extract the parameter posterior means: β,describe(chns)Plot the chainsplot(chns)end of m4.5d.jl#- This page was generated using Literate.jl."
},

{
    "location": "05/m5.3d/#",
    "page": "m5.3d",
    "title": "m5.3d",
    "category": "page",
    "text": "EditURL = \"https://github.com/StatisticalRethinkingJulia/DynamicHMCModels.jl/blob/master/scripts/05/m5.3d.jl\""
},

{
    "location": "05/m5.3d/#Linear-regression-1",
    "page": "m5.3d",
    "title": "Linear regression",
    "category": "section",
    "text": "using DynamicHMCModels\n\nProjDir = rel_path_d(\"..\", \"scripts\", \"05\")\ncd(ProjDir)Import the dataset."
},

{
    "location": "05/m5.3d/#snippet-5.4-1",
    "page": "m5.3d",
    "title": "snippet 5.4",
    "category": "section",
    "text": "wd = CSV.read(rel_path(\"..\", \"data\", \"WaffleDivorce.csv\"), delim=\';\')\ndf = convert(DataFrame, wd);\n\nmean_ma = mean(df[:Marriage])\ndf[:Marriage_s] = convert(Vector{Float64},\n  (df[:Marriage]) .- mean_ma)/std(df[:Marriage]);\n\nmean_mam = mean(df[:MedianAgeMarriage])\ndf[:MedianAgeMarriage_s] = convert(Vector{Float64},\n  (df[:MedianAgeMarriage]) .- mean_mam)/std(df[:MedianAgeMarriage]);Show the first six rows of the dataset.first(df[[1, 7, 14,15]], 6)Model y  Xβ + ϵ, where ϵ  N(0 σ²) IID. Student prior on σstruct m_5_3{TY <: AbstractVector, TX <: AbstractMatrix}\n    \"Observations.\"\n    y::TY\n    \"Covariates\"\n    X::TX\nendMake the type callable with the parameters as a single argument.function (problem::m_5_3)(θ)\n    @unpack y, X, = problem   # extract the data\n    @unpack β, σ = θ            # works on the named tuple too\n    ll = 0.0\n    ll += logpdf(Normal(10, 10), X[1]) # a = X[1]\n    ll += logpdf(Normal(0, 1), X[2]) # b1 = X[2]\n    ll += logpdf(Normal(0, 1), X[3]) # b1 = X[3]\n    ll += logpdf(TDist(1.0), σ)\n    ll += loglikelihood(Normal(0, σ), y .- X*β)\n    ll\nendInstantiate the model with data and inits.N = size(df, 1)\nX = hcat(ones(N), df[:Marriage_s], df[:MedianAgeMarriage_s]);\ny = convert(Vector{Float64}, df[:Divorce])\np = m_5_3(y, X);\np((β = [1.0, 2.0, 3.0], σ = 1.0))Write a function to return properly dimensioned transformation.problem_transformation(p::m_5_3) =\n    as((β = as(Array, size(p.X, 2)), σ = asℝ₊))Wrap the problem with a transformation, then use Flux for the gradient.P = TransformedLogDensity(problem_transformation(p), p)\n∇P = LogDensityRejectErrors(ADgradient(:ForwardDiff, P));Tune and sample.chain, NUTS_tuned = NUTS_init_tune_mcmc(∇P, 1000);We use the transformation to obtain the posterior from the chain.posterior = TransformVariables.transform.(Ref(problem_transformation(p)), get_position.(chain));\nposterior[1:5]Extract the parameter posterior means: β,posterior_β = mean(first, posterior)then σ:posterior_σ = mean(last, posterior)Effective sample sizes (of untransformed draws)ess = mapslices(effective_sample_size,\n                get_position_matrix(chain); dims = 1)NUTS-specific statisticsNUTS_statistics(chain)cmdstan resultcmdstan_result = \"\nIterations = 1:1000\nThinning interval = 1\nChains = 1,2,3,4\nSamples per chain = 1000\n\nEmpirical Posterior Estimates:\n          Mean        SD       Naive SE       MCSE      ESS\n    a  9.69137275 0.21507432 0.0034006235 0.0038501180 1000\n   bA -1.12184710 0.29039965 0.0045916216 0.0053055477 1000\n   bM -0.12106472 0.28705400 0.0045387223 0.0051444688 1000\nsigma  1.52326545 0.16272599 0.0025729239 0.0034436330 1000\n\nQuantiles:\n         2.5%       25.0%      50.0%      75.0%       97.5%\n    a  9.2694878  9.5497650  9.6906850  9.83227750 10.11643500\n   bA -1.6852295 -1.3167700 -1.1254650 -0.92889225 -0.53389157\n   bM -0.6889247 -0.3151695 -0.1231065  0.07218513  0.45527243\nsigma  1.2421182  1.4125950  1.5107700  1.61579000  1.89891925\n\";Extract the parameter posterior means: [β, σ],[posterior_β, posterior_σ]end of m4.5d.jl#- This page was generated using Literate.jl."
},

{
    "location": "05/m5.6d/#",
    "page": "m5.6d",
    "title": "m5.6d",
    "category": "page",
    "text": "EditURL = \"https://github.com/StatisticalRethinkingJulia/DynamicHMCModels.jl/blob/master/scripts/05/m5.6d.jl\"Load Julia packages (libraries) needed  for the snippets in chapter 0using DynamicHMCModelsCmdStan uses a tmp directory to store the output of cmdstanProjDir = rel_path_d(\"..\", \"scripts\", \"05\")\ncd(ProjDir)Read the milk datawd = CSV.read(rel_path(\"..\", \"data\", \"milk.csv\"), delim=\';\')\ndf = convert(DataFrame, wd);\ndcc = filter(row -> !(row[:neocortex_perc] == \"NA\"), df)\ndcc[:kcal_per_g] = convert(Vector{Float64}, dcc[:kcal_per_g])\ndcc[:log_mass] = log.(convert(Vector{Float64}, dcc[:mass]))Show first 5 rowsfirst(dcc[[3, 7, 9]], 5)Define the model structstruct m_5_6{TY <: AbstractVector, TX <: AbstractMatrix}\n    \"Observations.\"\n    y::TY\n    \"Covariates\"\n    X::TX\nendMake the type callable with the parameters as a single argument.function (problem::m_5_6)(θ)\n    @unpack y, X, = problem   # extract the data\n    @unpack β, σ = θ            # works on the named tuple too\n    ll = 0.0\n    ll += logpdf(Normal(0, 100), X[1]) # a = X[1]\n    ll += logpdf(Normal(0, 1), X[2]) # b1 = X[2]\n    ll += logpdf(TDist(1.0), σ)\n    ll += loglikelihood(Normal(0, σ), y .- X*β)\n    ll\nendInstantiate the model with data and inits.N = size(dcc, 1)\nX = hcat(ones(N), dcc[:log_mass]);\ny = dcc[:kcal_per_g]\np = m_5_6(y, X);\np((β = [1.0, 2.0], σ = 1.0))Write a function to return properly dimensioned transformation.problem_transformation(p::m_5_6) =\n    as((β = as(Array, size(p.X, 2)), σ = asℝ₊))Wrap the problem with a transformation, then use Flux for the gradient.P = TransformedLogDensity(problem_transformation(p), p)\n∇P = LogDensityRejectErrors(ADgradient(:ForwardDiff, P));Tune and sample.chain, NUTS_tuned = NUTS_init_tune_mcmc(∇P, 1000);We use the transformation to obtain the posterior from the chain.posterior = TransformVariables.transform.(Ref(problem_transformation(p)), get_position.(chain));\nposterior[1:5]Extract the parameter posterior means: β,posterior_β = mean(first, posterior)then σ:posterior_σ = mean(last, posterior)Effective sample sizes (of untransformed draws)ess = mapslices(effective_sample_size,\n                get_position_matrix(chain); dims = 1)NUTS-specific statisticsNUTS_statistics(chain)cmdstan resultcmdstan_result = \"\nIterations = 1:1000\nThinning interval = 1\nChains = 1,2,3,4\nSamples per chain = 1000\n\nEmpirical Posterior Estimates:\n          Mean         SD        Naive SE       MCSE      ESS\n    a  0.70472876 0.057040655 0.00090189195 0.0011398893 1000\n   bm -0.03150330 0.023642759 0.00037382484 0.0004712342 1000\nsigma  0.18378372 0.039212805 0.00062000888 0.0011395979 1000\n\nQuantiles:\n          2.5%       25.0%       50.0%        75.0%       97.5%\n    a  0.59112968  0.66848775  0.70444950  0.741410500 0.81915225\n   bm -0.07729257 -0.04708425 -0.03104865 -0.015942925 0.01424901\nsigma  0.12638780  0.15605950  0.17800600  0.204319250 0.27993590\n\";Extract the parameter posterior means: [β, σ],[posterior_β, posterior_σ]End of 05/5.6d.jlThis page was generated using Literate.jl."
},

{
    "location": "08/m8.1d/#",
    "page": "m8.1d",
    "title": "m8.1d",
    "category": "page",
    "text": "EditURL = \"https://github.com/StatisticalRethinkingJulia/DynamicHMCModels.jl/blob/master/scripts/08/m8.1d.jl\"Load Julia packages (libraries) needed  for the snippets in chapter 0using DynamicHMCModelsCmdStan uses a tmp directory to store the output of cmdstanProjDir = rel_path_d(\"..\", \"scripts\", \"08\")\ncd(ProjDir)"
},

{
    "location": "08/m8.1d/#snippet-5.1-1",
    "page": "m8.1d",
    "title": "snippet 5.1",
    "category": "section",
    "text": "d = CSV.read(rel_path(\"..\", \"data\", \"rugged.csv\"), delim=\';\');\ndf = convert(DataFrame, d);\n\ndcc = filter(row -> !(ismissing(row[:rgdppc_2000])), df)\ndcc[:log_gdp] = log.(dcc[:rgdppc_2000])\ndcc[:cont_africa] = Array{Float64}(convert(Array{Int}, dcc[:cont_africa]))First 5 rows with datafirst(dcc[[:rugged, :cont_africa, :log_gdp]], 5)\n\nstruct m_8_1_model{TY <: AbstractVector, TX <: AbstractMatrix}\n    \"Observations.\"\n    y::TY\n    \"Covariates\"\n    X::TX\nendMake the type callable with the parameters as a single argument.function (problem::m_8_1_model)(θ)\n    @unpack y, X, = problem   # extract the data\n    @unpack β, σ = θ            # works on the named tuple too\n    ll = 0.0\n    ll += logpdf(Normal(0, 100), X[1]) # a = X[1]\n    ll += logpdf(Normal(0, 10), X[2]) # bR = X[2]\n    ll += logpdf(Normal(0, 10), X[3]) # bA = X[3]\n    ll += logpdf(Normal(0, 10), X[4]) # bAR = X[4]\n    ll += logpdf(TDist(1.0), σ)\n    ll += loglikelihood(Normal(0, σ), y .- X*β)\n    ll\nendInstantiate the model with data and inits.N = size(dcc, 1)\nX = hcat(ones(N), dcc[:rugged], dcc[:cont_africa], dcc[:rugged].*dcc[:cont_africa]);\ny = convert(Vector{Float64}, dcc[:log_gdp])\np = m_8_1_model(y, X);\np((β = [1.0, 2.0, 1.0, 2.0], σ = 1.0))Write a function to return properly dimensioned transformation.problem_transformation(p::m_8_1_model) =\n    as((β = as(Array, size(p.X, 2)), σ = asℝ₊))Wrap the problem with a transformation, then use Flux for the gradient.P = TransformedLogDensity(problem_transformation(p), p)\n∇P = LogDensityRejectErrors(ADgradient(:ForwardDiff, P));Tune and sample.chain, NUTS_tuned = NUTS_init_tune_mcmc(∇P, 1000);We use the transformation to obtain the posterior from the chain.posterior = TransformVariables.transform.(Ref(problem_transformation(p)), get_position.(chain));\nposterior[1:5]Extract the parameter posterior means: β,posterior_β = mean(first, posterior)then σ:posterior_σ = mean(last, posterior)Effective sample sizes (of untransformed draws)ess = mapslices(effective_sample_size,\n                get_position_matrix(chain); dims = 1)NUTS-specific statisticsNUTS_statistics(chain)Result rethinkingrethinking = \"\n       mean   sd  5.5% 94.5% n_eff Rhat\na      9.22 0.14  9.00  9.46   282    1\nbR    -0.21 0.08 -0.33 -0.08   275    1\nbA    -1.94 0.24 -2.33 -1.59   268    1\nbAR    0.40 0.14  0.18  0.62   271    1\nsigma  0.96 0.05  0.87  1.04   339    1\n\"Summary[posterior_β, posterior_σ]End of 08/m8.1s.jlThis page was generated using Literate.jl."
},

{
    "location": "10/m10.02d/#",
    "page": "m10.02d",
    "title": "m10.02d",
    "category": "page",
    "text": "EditURL = \"https://github.com/StatisticalRethinkingJulia/DynamicHMCModels.jl/blob/master/scripts/10/m10.02d.jl\"Load Julia packages (libraries) needed  for the snippets in chapter 0using DynamicHMCModels"
},

{
    "location": "10/m10.02d/#snippet-10.4-1",
    "page": "m10.02d",
    "title": "snippet 10.4",
    "category": "section",
    "text": "d = CSV.read(rel_path(\"..\", \"data\", \"chimpanzees.csv\"), delim=\';\');\ndf = convert(DataFrame, d);\ndf[:pulled_left] = convert(Array{Int64}, df[:pulled_left])\ndf[:prosoc_left] = convert(Array{Int64}, df[:prosoc_left])\nfirst(df, 5)\n\nstruct m_10_02d_model{TY <: AbstractVector, TX <: AbstractMatrix}\n    \"Observations.\"\n    y::TY\n    \"Covariates\"\n    X::TX\n    \"Number of observations\"\n    N::Int\nendMake the type callable with the parameters as a single argument.function (problem::m_10_02d_model)(θ)\n    @unpack y, X, N = problem   # extract the data\n    @unpack β = θ  # works on the named tuple too\n    ll = 0.0\n    ll += sum(logpdf.(Normal(0, 10), β)) # a & bp\n    ll += sum([loglikelihood(Binomial(1, logistic(dot(X[i, :], β))), [y[i]]) for i in 1:N])\n    ll\nendInstantiate the model with data and inits.N = size(df, 1)\nX = hcat(ones(Int64, N), df[:prosoc_left]);\ny = df[:pulled_left]\np = m_10_02d_model(y, X, N);\nθ = (β = [1.0, 2.0],)\np(θ)Write a function to return properly dimensioned transformation.problem_transformation(p::m_10_02d_model) =\n    as( (β = as(Array, size(p.X, 2)), ) )Wrap the problem with a transformation, then use Flux for the gradient.P = TransformedLogDensity(problem_transformation(p), p)\n∇P = LogDensityRejectErrors(ADgradient(:ForwardDiff, P));Tune and sample.chain, NUTS_tuned = NUTS_init_tune_mcmc(∇P, 1000);We use the transformation to obtain the posterior from the chain.posterior = TransformVariables.transform.(Ref(problem_transformation(p)), get_position.(chain));\nposterior[1:5]Extract the parameter posterior means: β,posterior_β = mean(first, posterior)Effective sample sizes (of untransformed draws)ess = mapslices(effective_sample_size, get_position_matrix(chain); dims = 1)\nessNUTS-specific statisticsNUTS_statistics(chain)CmdStan resultm_10_2s_result = \"\nIterations = 1:1000\nThinning interval = 1\nChains = 1,2,3,4\nSamples per chain = 1000\n\nEmpirical Posterior Estimates:\n      Mean        SD       Naive SE       MCSE      ESS\n a 0.05103234 0.12579086 0.0019889282 0.0035186307 1000\nbp 0.55711212 0.18074275 0.0028577937 0.0040160451 1000\n\nQuantiles:\n       2.5%        25.0%       50.0%      75.0%      97.5%\n a -0.19755400 -0.029431425 0.05024655 0.12978825 0.30087758\nbp  0.20803447  0.433720250 0.55340400 0.67960975 0.91466915\n\";Extract the parameter posterior means: β,posterior_β = mean(first, posterior)End of 10/m10.02d.jlThis page was generated using Literate.jl."
},

{
    "location": "10/m10.02d1/#",
    "page": "m10.02d1",
    "title": "m10.02d1",
    "category": "page",
    "text": "EditURL = \"https://github.com/StatisticalRethinkingJulia/DynamicHMCModels.jl/blob/master/scripts/10/m10.02d1.jl\"Load Julia packages (libraries) needed  for the snippets in chapter 0using DynamicHMCModels, Optim"
},

{
    "location": "10/m10.02d1/#snippet-10.4-1",
    "page": "m10.02d1",
    "title": "snippet 10.4",
    "category": "section",
    "text": "d = CSV.read(rel_path(\"..\", \"data\", \"chimpanzees.csv\"), delim=\';\');\ndf = convert(DataFrame, d);\ndf[:pulled_left] = convert(Array{Int64}, df[:pulled_left])\ndf[:prosoc_left] = convert(Array{Int64}, df[:prosoc_left])\nfirst(df, 5)\n\nstruct m_10_02d{TY <: AbstractVector, TX <: AbstractMatrix}\n    \"Observations.\"\n    y::TY\n    \"Covariates\"\n    X::TX\n    \"Number of observations\"\n    N::Int\nendMake the type callable with the parameters as a single argument.function (problem::m_10_02d)(θ)\n    @unpack y, X, N = problem   # extract the data\n    @unpack β = trans(θ)  # works on the named tuple too\n    ll = 0.0\n    ll += sum(logpdf.(Normal(0, 10), β)) # a & bp\n    ll += sum([loglikelihood(Binomial(1, logistic(dot(X[i, :], β))), [y[i]]) for i in 1:N])\n    ll\nendInstantiate the model with data and inits.N = size(df, 1)\nX = hcat(ones(Int64, N), df[:prosoc_left]);\ny = df[:pulled_left]\np = m_10_02d(y, X, N);Function convert from a single vector of parms to parks NamedTupletrans = as( (β = as(Array, size(p.X, 2)), ));\n\nγ =  (β = [0.5, 1.0],)\nθ = inverse(trans, γ)\np(θ)Maximumapostriorx0 = θ;\nlower = [-1.0, -1.0];\nupper = [1.0, 2.0];\nll(x) = -p(x)\n\ninner_optimizer = GradientDescent()\n\noptimize(ll, lower, upper, x0, Fminbox(inner_optimizer))Write a function to return properly dimensioned transformation.problem_transformation(p::m_10_02d) =as( (β = as(Array, size(p.X, 2)), ) )      as( Vector, size(p.X, 2))Wrap the problem with a transformation, then use Flux for the gradient.P = TransformedLogDensity(problem_transformation(p), p)\n∇P = LogDensityRejectErrors(ADgradient(:ForwardDiff, P));Tune and sample.chain, NUTS_tuned = NUTS_init_tune_mcmc(∇P, 1000);We use the transformation to obtain the posterior from the chain.posterior = TransformVariables.transform.(Ref(problem_transformation(p)), get_position.(chain));\nposterior[1:5]Extract the parameter posterior means: β,posterior_a = mean(first, posterior)\nposterior_bp = mean(last, posterior)Effective sample sizes (of untransformed draws)ess = mapslices(effective_sample_size, get_position_matrix(chain); dims = 1)\nessNUTS-specific statisticsNUTS_statistics(chain)CmdStan resultm_10_2s_result = \"\nIterations = 1:1000\nThinning interval = 1\nChains = 1,2,3,4\nSamples per chain = 1000\n\nEmpirical Posterior Estimates:\n      Mean        SD       Naive SE       MCSE      ESS\n a 0.05103234 0.12579086 0.0019889282 0.0035186307 1000\nbp 0.55711212 0.18074275 0.0028577937 0.0040160451 1000\n\nQuantiles:\n       2.5%        25.0%       50.0%      75.0%      97.5%\n a -0.19755400 -0.029431425 0.05024655 0.12978825 0.30087758\nbp  0.20803447  0.433720250 0.55340400 0.67960975 0.91466915\n\";Extract the parameter posterior means: β,[posterior_a, posterior_bp]End of 10/m10.02d.jlThis page was generated using Literate.jl."
},

{
    "location": "10/m10.04d/#",
    "page": "m10.04d",
    "title": "m10.04d",
    "category": "page",
    "text": "EditURL = \"https://github.com/StatisticalRethinkingJulia/DynamicHMCModels.jl/blob/master/scripts/10/m10.04d.jl\"Load Julia packages (libraries) needed  for the snippets in chapter 0using DynamicHMCModelsCmdStan uses a tmp directory to store the output of cmdstanProjDir = rel_path_d(\"..\", \"scripts\", \"10\")\ncd(ProjDir)"
},

{
    "location": "10/m10.04d/#snippet-10.4-1",
    "page": "m10.04d",
    "title": "snippet 10.4",
    "category": "section",
    "text": "d = CSV.read(rel_path(\"..\", \"data\", \"chimpanzees.csv\"), delim=\';\');\ndf = convert(DataFrame, d);\ndf[:pulled_left] = convert(Array{Int64}, df[:pulled_left])\ndf[:prosoc_left] = convert(Array{Int64}, df[:prosoc_left])\ndf[:condition] = convert(Array{Int64}, df[:condition])\ndf[:actor] = convert(Array{Int64}, df[:actor])\nfirst(df, 5)\n\nstruct m_10_04d_model{TY <: AbstractVector, TX <: AbstractMatrix,\n  TA <: AbstractVector}\n    \"Observations.\"\n    y::TY\n    \"Covariates\"\n    X::TX\n    \"Actors\"\n    A::TA\n    \"Number of observations\"\n    N::Int\n    \"Number of unique actors\"\n    N_actors::Int\nendMake the type callable with the parameters as a single argument.function (problem::m_10_04d_model)(θ)\n    @unpack y, X, A, N, N_actors = problem   # extract the data\n    @unpack β, α = θ  # works on the named tuple too\n    ll = 0.0\n    ll += sum(logpdf.(Normal(0, 10), β)) # bp & bpC\n    ll += sum(logpdf.(Normal(0, 10), α)) # alpha[1:7]\n    ll += sum(\n      [loglikelihood(Binomial(1, logistic(α[A[i]] + dot(X[i, :], β))), [y[i]]) for i in 1:N]\n    )\n    ll\nendInstantiate the model with data and inits.N = size(df, 1)\nN_actors = length(unique(df[:actor]))\nX = hcat(ones(Int64, N), df[:prosoc_left] .* df[:condition]);\nA = df[:actor]\ny = df[:pulled_left]\np = m_10_04d_model(y, X, A, N, N_actors);\nθ = (β = [1.0, 0.0], α = [-1.0, 10.0, -1.0, -1.0, -1.0, 0.0, 2.0])\np(θ)Write a function to return properly dimensioned transformation.problem_transformation(p::m_10_04d_model) =\n    as( (β = as(Array, size(p.X, 2)), α = as(Array, p.N_actors), ) )Wrap the problem with a transformation, then use Flux for the gradient.P = TransformedLogDensity(problem_transformation(p), p)\n∇P = LogDensityRejectErrors(ADgradient(:ForwardDiff, P));Tune and sample.chain, NUTS_tuned = NUTS_init_tune_mcmc(∇P, 1000);We use the transformation to obtain the posterior from the chain.posterior = TransformVariables.transform.(Ref(problem_transformation(p)), get_position.(chain));\nposterior[1:5]Extract the parameter posterior means: β,posterior_β = mean(first, posterior)Extract the parameter posterior means: β,posterior_α = mean(last, posterior)Effective sample sizes (of untransformed draws)ess = mapslices(effective_sample_size, get_position_matrix(chain); dims = 1)\nessNUTS-specific statisticsNUTS_statistics(chain)Result rethinkingrethinking = \"\nIterations = 1:1000\nThinning interval = 1\nChains = 1,2,3,4\nSamples per chain = 1000\n\nEmpirical Posterior Estimates:\n        Mean        SD       Naive SE       MCSE      ESS\na.1 -0.74503184 0.26613979 0.0042080396 0.0060183398 1000\na.2 10.77955494 5.32538998 0.0842018089 0.1269148045 1000\na.3 -1.04982353 0.28535997 0.0045119373 0.0049074219 1000\na.4 -1.04898135 0.28129307 0.0044476339 0.0056325117 1000\na.5 -0.74390933 0.26949936 0.0042611590 0.0052178124 1000\na.6  0.21599365 0.26307574 0.0041595927 0.0045153523 1000\na.7  1.81090866 0.39318577 0.0062168129 0.0071483527 1000\n bp  0.83979926 0.26284676 0.0041559722 0.0059795826 1000\nbpC -0.12913322 0.29935741 0.0047332562 0.0049519863 1000\n\";Means of draws[posterior_β, posterior_α]End of 10/m10.04d.jlThis page was generated using Literate.jl."
},

{
    "location": "12/m12.6d/#",
    "page": "m12.6d",
    "title": "m12.6d",
    "category": "page",
    "text": "EditURL = \"https://github.com/StatisticalRethinkingJulia/DynamicHMCModels.jl/blob/master/scripts/12/m12.6d.jl\"using DynamicHMCModels\n\nProjDir = rel_path_d(\"..\", \"scripts\", \"12\")\n\ndf = CSV.read(rel_path( \"..\", \"data\",  \"Kline.csv\"), delim=\';\');\nsize(df) # Should be 10x5New col logpop, set log() for population datadf[:logpop] = map((x) -> log(x), df[:population]);\ndf[:society] = 1:10;\n\nfirst(df[[:total_tools, :logpop, :society]], 5)\n\nstruct m_12_06d_model{TY <: AbstractVector, TX <: AbstractMatrix,\n  TS <: AbstractVector}\n    \"Observations (total_tools).\"\n    y::TY\n    \"Covariates (logpop)\"\n    X::TX\n    \"Society\"\n    S::TS\n    \"Number of observations (10)\"\n    N::Int\n    \"Number of societies (also 10)\"\n    N_societies::Int\nendMake the type callable with the parameters as a single argument.function (problem::m_12_06d_model)(θ)\n    @unpack y, X, S, N, N_societies = problem   # extract the data\n    @unpack β, α, σ = θ  # β : a, bp, α : a_society\n    ll = 0.0\n    ll += logpdf(Cauchy(0, 1), σ)\n    ll += sum(logpdf.(Normal(0, σ), α)) # α[1:10]\n    ll += logpdf.(Normal(0, 10), β[1]) # a\n    ll += logpdf.(Normal(0, 1), β[2]) # a\n    ll += sum(\n      [loglikelihood(Poisson(exp(α[S[i]] + dot(X[i, :], β))), [y[i]]) for i in 1:N]\n    )\n    ll\nendInstantiate the model with data and inits.N = size(df, 1)\nN_societies = length(unique(df[:society]))\nX = hcat(ones(Int64, N), df[:logpop]);\nS = df[:society]\ny = df[:total_tools]\np = m_12_06d_model(y, X, S, N, N_societies);\nθ = (β = [1.0, 0.25], α = rand(Normal(0, 1), N_societies), σ = 0.2)\np(θ)Write a function to return properly dimensioned transformation.problem_transformation(p::m_12_06d_model) =\n    as( (β = as(Array, size(p.X, 2)), α = as(Array, p.N_societies), σ = asℝ₊) )Wrap the problem with a transformation, then use Flux for the gradient.P = TransformedLogDensity(problem_transformation(p), p)\n∇P = LogDensityRejectErrors(ADgradient(:ForwardDiff, P));\n#∇P = ADgradient(:ForwardDiff, P);Tune and sample.chain, NUTS_tuned = NUTS_init_tune_mcmc(∇P, 1000);We use the transformation to obtain the posterior from the chain.posterior = TransformVariables.transform.(Ref(problem_transformation(p)), get_position.(chain));\nposterior[1:5]Extract the parameter posterior means.posterior_β = mean(posterior[i].β for i in 1:length(posterior))\nposterior_α = mean(posterior[i].α for i in 1:length(posterior))\nposterior_σ = mean(posterior[i].σ for i in 1:length(posterior))Effective sample sizes (of untransformed draws)ess = mapslices(effective_sample_size, get_position_matrix(chain); dims = 1)\nessNUTS-specific statisticsNUTS_statistics(chain)CmdStan resultm_12_6_result = \"\nIterations = 1:1000\nThinning interval = 1\nChains = 1,2,3,4\nSamples per chain = 1000\n\nEmpirical Posterior Estimates:\n                            Mean                SD               Naive SE             MCSE            ESS\n            a          1.076167468  0.7704872560 0.01218247319 0.0210530022 1000.000000\n           bp         0.263056273  0.0823415805 0.00130193470 0.0022645077 1000.000000\n  a_society.1   -0.191723568  0.2421382537 0.00382854195 0.0060563054 1000.000000\n  a_society.2    0.054569029  0.2278506876 0.00360263570 0.0051693148 1000.000000\n  a_society.3   -0.035935050  0.1926364647 0.00304584994 0.0039948433 1000.000000\n  a_society.4    0.334355037  0.1929971201 0.00305155241 0.0063871707  913.029080\n  a_society.5    0.049747513  0.1801287716 0.00284808595 0.0043631095 1000.000000\n  a_society.6   -0.311903245  0.2096126337 0.00331426674 0.0053000536 1000.000000\n  a_society.7    0.148637507  0.1744680594 0.00275858223 0.0047660246 1000.000000\n  a_society.8   -0.164567976  0.1821341074 0.00287979309 0.0034297298 1000.000000\n  a_society.9    0.277066965  0.1758237250 0.00278001719 0.0055844175  991.286501\n a_society.10   -0.094149204  0.2846206232 0.00450024719 0.0080735022 1000.000000\nsigma_society    0.310352849  0.1374834682 0.00217380450 0.0057325226  575.187461\n\";Show means[posterior_β, posterior_α, posterior_σ]End of m12.6d.jlThis page was generated using Literate.jl."
},

{
    "location": "12/m12.6d1/#",
    "page": "m12.6d1",
    "title": "m12.6d1",
    "category": "page",
    "text": "EditURL = \"https://github.com/StatisticalRethinkingJulia/DynamicHMCModels.jl/blob/master/scripts/12/m12.6d1.jl\"using DynamicHMCModels\n\nProjDir = rel_path_d(\"..\", \"scripts\", \"12\")\n\ndf = CSV.read(rel_path( \"..\", \"data\",  \"Kline.csv\"), delim=\';\');\nsize(df) # Should be 10x5New col logpop, set log() for population datadf[:society] = 1:10;\ndf[:logpop] = map((x) -> log(x), df[:population]);\n#df[:total_tools] = convert(Vector{Int64}, df[:total_tools])\nfirst(df[[:total_tools, :logpop, :society]], 5)Define problem data structurestruct m_12_06d{TY <: AbstractVector, TX <: AbstractMatrix,\n  TS <: AbstractVector}\n    \"Observations (total_tools).\"\n    y::TY\n    \"Covariates (logpop)\"\n    X::TX\n    \"Society\"\n    S::TS\n    \"Number of observations (10)\"\n    N::Int\n    \"Number of societies (also 10)\"\n    N_societies::Int\nend;Make the type callable with the parameters as a single argument.function (problem::m_12_06d)(θ)\n    @unpack y, X, S, N, N_societies = problem   # extract the data\n    @unpack β, α, s = trans(θ)  # β : a, bp, α : a_society, s\n    σ = s[1]^2\n    ll = 0.0\n    ll += logpdf(Cauchy(0, 1), σ) # sigma\n    ll += sum(logpdf.(Normal(0, σ), α)) # α[1:10]\n    ll += logpdf.(Normal(0, 10), β[1]) # a\n    ll += logpdf.(Normal(0, 1), β[2]) # bp\n    ll += sum(\n      [loglikelihood(Poisson(exp(α[S[i]] + dot(X[i, :], β))), [y[i]]) for i in 1:N]\n    )\nendInstantiate the model with data and inits.N = size(df, 1)\nN_societies = length(unique(df[:society]))\nX = hcat(ones(Int64, N), df[:logpop]);\nS = df[:society];\ny = df[:total_tools];\nγ = (β = [1.0, 0.25], α = rand(Normal(0, 1), N_societies), s = [0.2]);\np = m_12_06d(y, X, S, N, N_societies);Function convert from a single vector of parms to parks NamedTupletrans = as((β = as(Array, 2), α = as(Array, 10), s = as(Array, 1)));Define input parameter vectorθ = inverse(trans, γ);\np(θ)Maximumaposteriorusing Optim\n\nx0 = θ;\nlower = vcat([0.0, 0.0], -3ones(10), [0.0]);\nupper = vcat([2.0, 1.0], 3ones(10), [5.0]);\nll(x) = -p(x);\n\ninner_optimizer = GradientDescent()\n\nres = optimize(ll, lower, upper, x0, Fminbox(inner_optimizer));\nresMinimum gives MAP estimate:Optim.minimizer(res)Write a function to return properly dimensioned transformation.problem_transformation(p::m_12_06d) =\n  as( Vector, length(θ) )Wrap the problem with a transformation, then use ForwardDiff for the gradient.P = TransformedLogDensity(problem_transformation(p), p)\n∇P = LogDensityRejectErrors(ADgradient(:ForwardDiff, P));\n#∇P = ADgradient(:ForwardDiff, P);Tune and sample.chain, NUTS_tuned = NUTS_init_tune_mcmc(∇P, 1000);We use the transformation to obtain the posterior from the chain.posterior = TransformVariables.transform.(Ref(problem_transformation(p)), get_position.(chain));\nposterior[1:5]Extract the parameter posterior means.posterior_β = mean(trans(posterior[i]).β for i in 1:length(posterior))\nposterior_α = mean(trans(posterior[i]).α for i in 1:length(posterior))\nposterior_σ = mean(trans(posterior[i]).s for i in 1:length(posterior))[1]^2Effective sample sizes (of untransformed draws)ess = mapslices(effective_sample_size, get_position_matrix(chain); dims = 1)\nessNUTS-specific statisticsNUTS_statistics(chain)CmdStan resultm_12_6_result = \"\nIterations = 1:1000\nThinning interval = 1\nChains = 1,2,3,4\nSamples per chain = 1000\n\nEmpirical Posterior Estimates:\n                            Mean                SD               Naive SE             MCSE            ESS\n            a          1.076167468  0.7704872560 0.01218247319 0.0210530022 1000.000000\n           bp         0.263056273  0.0823415805 0.00130193470 0.0022645077 1000.000000\n  a_society.1   -0.191723568  0.2421382537 0.00382854195 0.0060563054 1000.000000\n  a_society.2    0.054569029  0.2278506876 0.00360263570 0.0051693148 1000.000000\n  a_society.3   -0.035935050  0.1926364647 0.00304584994 0.0039948433 1000.000000\n  a_society.4    0.334355037  0.1929971201 0.00305155241 0.0063871707  913.029080\n  a_society.5    0.049747513  0.1801287716 0.00284808595 0.0043631095 1000.000000\n  a_society.6   -0.311903245  0.2096126337 0.00331426674 0.0053000536 1000.000000\n  a_society.7    0.148637507  0.1744680594 0.00275858223 0.0047660246 1000.000000\n  a_society.8   -0.164567976  0.1821341074 0.00287979309 0.0034297298 1000.000000\n  a_society.9    0.277066965  0.1758237250 0.00278001719 0.0055844175  991.286501\n a_society.10   -0.094149204  0.2846206232 0.00450024719 0.0080735022 1000.000000\nsigma_society    0.310352849  0.1374834682 0.00217380450 0.0057325226  575.187461\n\";Show means[posterior_β, posterior_α, posterior_σ]End of m12.6d1.jlThis page was generated using Literate.jl."
},

{
    "location": "#",
    "page": "Functions",
    "title": "Functions",
    "category": "page",
    "text": "CurrentModule = DynamicHMCModels"
},

{
    "location": "#DynamicHMCModels.rel_path_d-Tuple",
    "page": "Functions",
    "title": "DynamicHMCModels.rel_path_d",
    "category": "method",
    "text": "relpathd\n\nRelative path using the DynamicHMCModels src/ directory. \n\nExample to get access to the data subdirectory\n\nrel_path_d(\"..\", \"data\")\n\n\n\n\n\n"
},

{
    "location": "#rel_path_d-1",
    "page": "Functions",
    "title": "rel_path_d",
    "category": "section",
    "text": "rel_path_d(parts...)"
},

{
    "location": "#DynamicHMCModels.generate_d-Tuple{}",
    "page": "Functions",
    "title": "DynamicHMCModels.generate_d",
    "category": "method",
    "text": "generate_d\n\nUtility function to generate all notebooks and chapters from scripts in the scripts directory.\n\nMethod\n\ngenerate_d(sd = script_dict_d)\n\nRequired arguments\n\nNone, all notebooks/.. and chapters/.. files are regenerated.\n\n\n\n\n\n"
},

{
    "location": "#DynamicHMCModels.generate_d-Tuple{AbstractString}",
    "page": "Functions",
    "title": "DynamicHMCModels.generate_d",
    "category": "method",
    "text": "generate\n\nGenerate notebooks and scripts in a single chapter.\n\nMethod\n\ngenerate(chapter::AbstractString)\n\nRequired arguments\n\nGenerate notebooks and scripts in a single chapter, e.g. generate(\"04\")\n\n\n\n\n\n"
},

{
    "location": "#DynamicHMCModels.generate_d-Tuple{AbstractString,AbstractString}",
    "page": "Functions",
    "title": "DynamicHMCModels.generate_d",
    "category": "method",
    "text": "generate\n\nGenerate a single notebook and script\n\nMethod\n\ngenerate(chapter::AbstractString, file::AbstractString)\n\nRequired arguments\n\nGenerate notebook and script file in chapter, e.g. generate(\"04\", \"m4.1d.jl\") or  generate(\"04/m4.1d.jl\")\n\n\n\n\n\n"
},

{
    "location": "#generate_d-1",
    "page": "Functions",
    "title": "generate_d",
    "category": "section",
    "text": "generate_d(; sd=script_dict_d_)\ngenerate_d(chapter::AbstractString; sd=script_dict_d_)\ngenerate_d(chapter::AbstractString, scriptfile::AbstractString; sd=script_dict_d_)"
},

]}
