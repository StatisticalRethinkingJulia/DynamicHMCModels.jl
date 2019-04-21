Pkg.add("StaticArrays")
Pkg.add("BenchmarkTools")
Pkg.add("MCMCDiagnostics")

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
  try
    Pkg.rm(pkg)
  catch
  end
end

for pkg in pkg_names
  spec = PackageSpec(url="https://github.com/chriselrod/$pkg.jl")
  Pkg.develop(spec)
  if pkg == "VectorizationBase"
    Pkg.build("VectorizationBase")
  end
end


using StaticArrays, PaddedMatrices, BenchmarkTools

# Create two StaticArrays

SA1 = @SMatrix randn(7,10);
SA2 = @SMatrix randn(10, 9);

# benchmark matrix multiplication

@benchmark $SA1 * $SA2

# Create two PaddedMatrices

PA1 = @Constant randn(7,10);
PA2 = @Constant randn(10, 9);

# benchmark matrix multiplication

@benchmark $PA1 * $PA2

# Create two StaticArrays 

SA3 = @SMatrix randn(16,42); 
SA4 = @SMatrix randn(42,14);

# benchmark matrix multiplication
@benchmark $SA3 * $SA4

 # Create two PaddedMatrices

PA3 = @Constant randn(16,42);
PA4 = @Constant randn(42,14);

# benchmark matrix multiplication

@benchmark $PA3 * $PA4

ProjDir = @__DIR__
cd(ProjDir)


