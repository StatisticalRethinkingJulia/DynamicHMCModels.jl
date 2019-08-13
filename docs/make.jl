using DynamicHMCModels
using Documenter

append!(page_list, [Pair("Functions", "index.md")])

makedocs(root = DOC_ROOT,
    modules = Module[],
    sitename = "DynamicHMCModels.jl",
    authors = "Rob Goedman, Richard Torkar, and contributors.",
    pages = page_list
)

deploydocs(root = DOC_ROOT,
    repo = "github.com/StatisticalRethinkingJulia/DynamicHMCModels.jl.git",
 )
