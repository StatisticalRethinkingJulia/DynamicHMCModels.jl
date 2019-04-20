using CmdStan

ProjDir = @__DIR__
cd(ProjDir)

if isfile("itp_02.jls") 
  itp_02 = read("itp_02.jls", Chains)
end