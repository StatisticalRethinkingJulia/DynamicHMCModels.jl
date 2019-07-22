using Distributions, BenchmarkTools
using StatsFuns
using Parameters: @unpack

import MacroTools: prewalk, postwalk, @q, striplines, replace, flatten, @capture
import MLStyle

function rejectionSample(y, numSamples)
  N = length(y)
  posteriorSample = zeros(numSamples)
  sampleNum = 1
  loopcount = 0
  while sampleNum <= numSamples
    p = rand(Uniform(0, 1))
    proposal = rand(Bernoulli(p), N)
    #proposal |> display
    if y == proposal
      posteriorSample[sampleNum] = p
      sampleNum += 1
    end
    loopcount += 1
  end
  return (posteriorSample, loopcount)
end

rejectionSample([1, 0, 1, 1], 5) |> display
println()

@btime rejectionSample([1, 0, 1, 1, 0, 1, 1], 20)

@time fit(Beta, rejectionSample([1,0,1,1,0,1,1,0], 100000)[1])

coin =@model y begin
  N = length(y)
  p ~ Uniform(0, 1)
  y ⩪ Bernoulli(p) |> iid(N)
end

