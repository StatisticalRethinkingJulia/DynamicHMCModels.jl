"""

Particles constructor for DynamicHMC
Convert DynamcHMC samples to a Particle NamedTuple
* `posterior`: an array of NamedTuple consisting of mcmc samples
"""
function as_particles(posterior)
    d = Dict{Symbol, Union{Particles, Vector{Particles}}}()
    pnt = posterior[1]
    for parm in keys(pnt)
        if size(pnt[parm], 1) > 1
            #(a3d, names) = nptoa3d(posterior)
            d[parm] = Particles[]

            for i in 1:size(pnt[parm], 1)
                temp = Float64[]
                for post in posterior
                    push!(temp, post[parm][i])
                end
                push!(d[parm], Particles(temp))
            end
        else
            temp = Float64[]
            for post in posterior
                push!(temp, post[parm])
            end
            d[parm] = Particles(temp)
        end
    end
    return (; d...)
end

function nptoa3d(posterior)
    Np = length(vcat(posterior[1]...))
    Ns = length(posterior)
    a3d = Array{Float64,3}(undef,Ns,Np,1)
    for (i,post) in enumerate(posterior)
        temp = Float64[]
        for p in post
            push!(temp,values(p)...)
        end
        a3d[i,:,1] = temp'
    end
    parameter_names = getnames(posterior)
    return (a3d, parameter_names)
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
    Particles,
    as_particles