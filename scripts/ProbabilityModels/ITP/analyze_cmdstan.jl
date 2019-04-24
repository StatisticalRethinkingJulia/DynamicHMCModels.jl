using CmdStan, StatsPlots

ProjDir = @__DIR__

stansummary = CMDSTAN_HOME*"/bin/stansummary"
set_tuples = Dict(
  :tmp1 => Dict(:name = "itp1", :chains => [1:4]], 
  :tmp1 => Dict(:name = "itp2", :chains => [1:4]], 
  :tmp1 => Dict(:name = "itp3", :chains => [1:2]], 
)

# Loop over all paths to where the samples were saved.
for path in String.(keys(filesets))
  resdir = joinpath(ProjDir, path)
  cd(resdir) do
    run(`$stansummary itp_samples_$[i for i ∈ chains].csv`)
  end
end

set_tuples = Dict(
  :tmp1 => Dict(:name = "itp1", :chains => [1:4]], 
  :tmp1 => Dict(:name = "itp2", :chains => [1:4]], 
  :tmp1 => Dict(:name = "itp3", :chains => [1:2]], 
)

#=
a3d, cnames = CmdStan.read_samples(stanmodel_itp);
chns = Chains(a3d, cnames)

#chns = chainscat(chns_itp1, chns_itp2)

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
=#