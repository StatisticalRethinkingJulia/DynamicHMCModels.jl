itp_samples = [constrain.(Ref(ℓ_itp), get_position.(chain)) for chain ∈ chains[converged]];

@show size(itp_samples)

@show size(itp_samples[1])

@show itp_samples[1][1]

@show itp_samples[1][1][:μh₁]

@show parm_names = keys(itp_samples[1][1])

@show length( itp_samples[1][1][:μᵣ₁])

# 9 x 9 matrix
@show length( itp_samples[1][1][:L]);

println()

#=
# Set varable names

parameter_names = ["bp", "bpC"]
pooled_parameter_names = ["a[$i]" for i in 1:7]

# Create a3d

a3d = Array{Float64, 3}(undef, 1000, 9, 4);
for j in 1:4
  for i in 1:1000
    a3d[i, 1:2, j] = values(posterior[j][i][1])
    a3d[i, 3:9, j] = values(posterior[j][i][2])
  end
end

chns = MCMCChains.Chains(a3d,
  vcat(parameter_names, pooled_parameter_names),
  Dict(
    :parameters => parameter_names,
    :pooled => pooled_parameter_names
  )
);

# Describe the chain

describe(chns)

=#