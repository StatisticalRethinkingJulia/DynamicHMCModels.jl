pkg_names = [
  "VectorizationBase",
  "SIMDPirates",
  "SLEEFPirates",
  "VectorizedRNG",
  "LoopVectorization",
  "PaddedMatrices",
  "ScatteredArrays",
  "StructuredMatrices",
  "DistributionParameters",
  "ProbabilityDistributions",
  "ProbabilityModels"
]

for pkg in pkg_names
  spec = PackageSpec(url="https://github.com/chriselrod/$pkg.jl", rev="master")
  Pkg.add(spec)
  if pkg == "VectorizationBase"
    Pkg.build("VectorizationBase")
  end
end

spec = PackageSpec(url="https://github.com/cscherrer/Soss.jl", rev="master")
Pkg.add(spec)

ProjDir = @__DIR__
cd(ProjDir)

include(joinpath(ProjDir, "LogisticRegressionModel", "lr_pm.jl"))

ProjDir = @__DIR__
cd(ProjDir)

include(joinpath(ProjDir, "LogisticRegressionModel", "lr_pm.jl"))
