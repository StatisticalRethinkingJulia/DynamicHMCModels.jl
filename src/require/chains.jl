import MCMCChains: Chains

function create_a3d(noofsamples, noofvariables, noofchains)
   a3d = fill(0.0, noofsamples, noofvariables, noofchains)
   a3d
 end
 
 function insert_chain!(a3d, chain, posterior, trans)
   for i in 1:size(a3d, 1)
     a3d[i,:,chain] = inverse(trans, posterior[i])
   end
 end

 function insert_chain!(a3d, chain, posterior)
   for i in 1:size(a3d, 1)
     a3d[i,:,chain] = posterior[i, :]
   end
 end

 function create_mcmcchains(a3d, cnames;start=1)
   Chains(a3d, cnames; start=start)
 end
 
 function create_mcmcchains(a3d, cnames, sections::Dict{Symbol, Vector{String}};
   start=1)
   Chains(a3d, cnames, sections; start=start)
 end

"""
Convert DynamcHMC samples to a chain
* `posterior`: an array of NamedTuple consisting of mcmc samples
"""
function nptochain(posterior,tune)
    Np = length(vcat(posterior[1]...))+1 #include lf_eps
    Ns = length(posterior)
    a3d = Array{Float64,3}(undef,Ns,Np,1)
    ϵ=tune.ϵ
    for (i,post) in enumerate(posterior)
        temp = Float64[]
        for p in post
            push!(temp,values(p)...)
        end
        push!(temp,ϵ)
        a3d[i,:,1] = temp'
    end
    parameter_names = getnames(posterior)
    push!(parameter_names,"lf_eps")
    chns = MCMCChains.Chains(a3d,parameter_names,
        Dict(:internals => ["lf_eps"]))
    return chns
end

function getnames(post)
    nt = post[1]
    Np =length(vcat(nt...))
    parm_names = fill("",Np)
    cnt = 0
    for (k,v) in pairs(nt)
        N = length(v)
        if isa(v,Array)
            for i in 1:N
                cnt += 1
                parm_names[cnt] = string(k,"[",i,"]")
            end
        else
            cnt+=1
            parm_names[cnt] = string(k)
        end
    end
    return parm_names
end

export
  create_a3d,
  insert_chain!,
  nptochain,
  create_mcmcchains
