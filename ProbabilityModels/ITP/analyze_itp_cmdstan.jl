using CmdStan, StatsPlots

ProjDir = @__DIR__

stansummary = CMDSTAN_HOME*"/bin/stansummary"
set_tuple = (
  tmp1 = (name = "itp1", chains = 1:4, num_samples=2000), 
  tmp2 = (name = "itp1", chains = 1:4, num_samples=2000), 
  tmp3 = (name = "itp", chains = 1:2, num_samples=2000) 
);

# Loop over all paths to where the samples were saved.
for key in keys(set_tuple)
  theset = set_tuple[key]
  resdir = joinpath(ProjDir, String(key))
  m = Stanmodel(name = theset.name,
    num_samples=theset.num_samples)
  
  cd(resdir) do
    #run(`$stansummary $(m.name)_samples_$[i for i ∈ theset.chains].csv`)
  end
end

# Valid chains can be obtained from above stnsummary runs
set_tuple = (
  tmp1 = (name = "itp1", chains = [1, 3, 4], num_samples=2000), 
  tmp2 = (name = "itp1", chains = 1:3, num_samples=2000), 
  #tmp3 = (name = "itp", chains = 2:2, num_samples=2000) 
);

# Loop over all valid sets of samples
chns_array = Vector(undef, length(set_tuple))
for (i, key) in enumerate(keys(set_tuple))
  theset = set_tuple[key]
  # Where is teset saved?
  resdir = joinpath(ProjDir, String(key))
  # Dummy Stanmodel, name and num_samples need to be correct
  m = Stanmodel(name = theset.name,
    num_samples=theset.num_samples)
  
  cd(resdir) do
    run(`$stansummary $(m.name)_samples_$[i for i ∈ theset.chains].csv`)
    a3d, cnames = CmdStan.read_samples(m)
    chns_array[i] = Chains(a3d[:, :, theset.chains], cnames)    
  end
end

chns = chainscat(chns_array...)

chns_itp = set_section(chns, Dict(
  :parameters => ["muh.1", "muh.2", "rho"],
  :sigma_beta => ["sigma_beta", "sigma_h"],
  :L => reshape(["L.$i.$j" for i in 1:9, j in 1:9], 81),
  :betaraw => reshape(["betaraw.$i.$j" for i in 1:2, j in 1:9], 18),
  :kappa => ["kappa.$i" for i in 1:9],
  :sigma => ["sigma.$i" for i in 1:9],
  :theta => ["theta.$i" for i in 1:9],
  :muraw => reshape(["muraw.$i.$j" for i in 1:2, j in 1:4], 8),
  :internals => ["lp__", "accept_stat__", "stepsize__", "treedepth__", "n_leapfrog__",
    "divergent__", "energy__"]
  )
)

write("itp_sections.jls", chns_itp)
pfig = plot(chns_itp)
savefig(pfig, joinpath(ProjDir, "itp.pdf"))

show(chns_itp)

describe(chns_itp, sections=[:internals])
