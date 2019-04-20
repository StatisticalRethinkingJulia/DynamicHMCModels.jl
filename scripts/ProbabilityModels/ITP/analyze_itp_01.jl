using CmdStan

ProjDir = @__DIR__
cd(ProjDir)

itp_01 = isfile("itp_01.jls") && read("itp_01.jls", Chains)