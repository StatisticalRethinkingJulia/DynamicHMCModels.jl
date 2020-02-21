import MonteCarloMeasurements: Particles

"""

Particles constructor for DynamicHMC
Convert DynamcHMC samples to a Particle NamedTuple
* `posterior`: an array of NamedTuple consisting of mcmc samples
"""
function Particles(posterior)
    d = Dict()
    parms = getnames(posterior)
    for (i, post) in enumerate(posterior)
        temp = Float64[]
        for p in post
            push!(temp,values(p)...)
        end
        d[parms[i]] = Particles(temp)
    end
    return (; dct...)
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
    return Symbol.(parm_names)
end

export
    Particles