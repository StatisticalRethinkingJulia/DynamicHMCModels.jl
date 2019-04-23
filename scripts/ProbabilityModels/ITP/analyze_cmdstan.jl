using CmdStan, StatsPlots

ProjDir = @__DIR__
cd(joinpath(ProjDir, "tmp"))

chains = [1, 2]
stansummary = CMDSTAN_HOME*"/bin/stansummary"

# path to where the samples were saved.
resdir = joinpath(ProjDir, "tmp")
run(`$stansummary itp1_samples_$[i for i ∈ chains].csv`)

a3d, cnames = CmdStan.read_samples(stanmodel_itp);
chns_itp1 = Chains(a3d, cnames)
pfig1 = plot(chns_itp1[["muh.1", "muh.2", "rho"]])
savefig(pfig1, joinpath(ProjDir, "itp_1.pdf"))

cd(joinpath(ProjDir, "tmp2"))
chns_itp2 = Chains(a3d, cnames)
pfig2 = plot(chns_itp1[["muh.1", "muh.2", "rho"]])
savefig(pfig2, joinpath(ProjDir, "itp_2.pdf"))

chns = chainscat(chns_itp1, chns_itp2)

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
pfig3 = plot(chns_itp)
savefig(pfig3, joinpath(ProjDir, "itp.pdf"))
