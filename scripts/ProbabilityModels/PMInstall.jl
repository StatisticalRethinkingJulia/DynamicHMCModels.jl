pkgs = [
    PackageSpec(url="https://github.com/chriselrod/VectorizationBase.jl"),
    PackageSpec(url="https://github.com/chriselrod/SIMDPirates.jl"),
    PackageSpec(url="https://github.com/chriselrod/SLEEFPirates.jl"),
    PackageSpec(url="https://github.com/chriselrod/VectorizedRNG.jl"),
    PackageSpec(url="https://github.com/chriselrod/LoopVectorization.jl"),
    PackageSpec(url="https://github.com/chriselrod/PaddedMatrices.jl"),
    PackageSpec(url="https://github.com/chriselrod/ScatteredArrays.jl"),
    PackageSpec(url="https://github.com/chriselrod/StructuredMatrices.jl"),
    PackageSpec(url="https://github.com/chriselrod/DistributionParameters.jl"),
    PackageSpec(url="https://github.com/chriselrod/ProbabilityDistributions.jl"),
    PackageSpec(url="https://github.com/chriselrod/ProbabilityModels.jl")
]

for pkg in pkgs
  Pkg.develop(pkg)
end

Pkg.build("VectorizationBase")

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