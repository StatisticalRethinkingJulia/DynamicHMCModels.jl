### A Pluto.jl notebook ###
# v0.19.22

using Markdown
using InteractiveUtils

# ╔═╡ 28f7bd2f-3208-4c61-ad19-63b11dd56d30
using Pkg

# ╔═╡ 2846bc48-7972-49bc-8233-80c7ea3326e6
begin
	using DataFrames
    using RegressionAndOtherStories: reset_selected_notebooks_in_notebooks_df!
end

# ╔═╡ 70d5fba2-aec1-444e-a913-39947747a355
#Pkg.activate(expanduser("~/.julia/dev/SR2StanPluto"))

# ╔═╡ 970efecf-9ae7-4771-bff0-089202b1ff1e
html"""
<style>
	main {
		margin: 0 auto;
		max-width: 3500px;
    	padding-left: max(5px, 5%);
    	padding-right: max(5px, 20%);
	}
</style>
"""

# ╔═╡ d98a3a0a-947e-11ed-13a2-61b5b69b4df5
notebook_files = [
    "~/.julia/dev/SR2StanPluto/notebooks/00-Preface.jl",
    "~/.julia/dev/SR2StanPluto/notebooks/02-Small Worlds and Large World.jl",
    "~/.julia/dev/SR2StanPluto/notebooks/03-Sampling the imaginary.jl",
    "~/.julia/dev/SR2StanPluto/notebooks/04.1-Why normal distributions are normal.jl",
    "~/.julia/dev/SR2StanPluto/notebooks/04.2-A language for describing models.jl",
    "~/.julia/dev/SR2StanPluto/notebooks/04.3-Gaussian model of height.jl",
    "~/.julia/dev/SR2StanPluto/notebooks/04.4-Linear prediction.jl",
    "~/.julia/dev/SR2StanPluto/notebooks/04.5-Curves from lines.jl",
    "~/.julia/dev/SR2StanPluto/notebooks/05.1-Spurious associations.jl",
    "~/.julia/dev/SR2StanPluto/notebooks/05.2-Masked relationships.jl",
    "~/.julia/dev/SR2StanPluto/notebooks/05.3-Categorical variables.jl",
    "~/.julia/dev/SR2StanPluto/notebooks/09.1-Good King Markov.jl",
    "~/.julia/dev/SR2StanPluto/notebooks/09.2-Metropolis algorithm.jl",
    "~/.julia/dev/SR2StanPluto/notebooks/09.3-Hamiltonian Monte Carlo.jl",
    "~/.julia/dev/SR2StanPluto/notebooks/09.4-Easy HMC.jl",
    "~/.julia/dev/SR2StanPluto/notebooks/09.5-Care of Markov chains.jl",
	
    "~/.julia/dev/SR2StanPluto/notebooks/CausalInference/PC Algorithm: Basic example.jl",
    "~/.julia/dev/SR2StanPluto/notebooks/CausalInference/PC Algorithm: Example with real data.jl",
    "~/.julia/dev/SR2StanPluto/notebooks/CausalInference/PC Algorithm: Further example.jl",
    "~/.julia/dev/SR2StanPluto/notebooks/CausalInference/PC Algorithm: How it works.jl",
    "~/.julia/dev/SR2StanPluto/notebooks/CausalInference/PC Algorithm: Reasoning about experiments.jl",
	
	"~/.julia/dev/SR2StanPluto/notebooks/Maintenance/Notebook-to-reset-SR2StanPluto-jl-notebooks.jl"
];

# ╔═╡ 0f10a758-e442-4cd8-88bc-d82d8de97ede
begin
    files = AbstractString[]
    for i in 1:length(notebook_files)
        append!(files, [split(notebook_files[i], "/")[end]])
    end
    notebooks_df = DataFrame(
        name = files,
        reset = repeat([false], length(notebook_files)),
        done = repeat([false], length(notebook_files)),
        file = notebook_files,
    )
end

# ╔═╡ a4207232-61eb-4da7-8629-1bcc670ab524
notebooks_df.reset .= true;

# ╔═╡ 722d4847-2458-4b23-b6a0-d1c321710a2a
notebooks_df

# ╔═╡ 9d94bebb-fc41-482f-8759-cdf224ec71fb
reset_selected_notebooks_in_notebooks_df!(notebooks_df; reset_activate=true, set_activate=false)

# ╔═╡ 88720478-7f64-4852-8683-6be50793666a
notebooks_df

# ╔═╡ Cell order:
# ╠═28f7bd2f-3208-4c61-ad19-63b11dd56d30
# ╠═70d5fba2-aec1-444e-a913-39947747a355
# ╠═2846bc48-7972-49bc-8233-80c7ea3326e6
# ╠═970efecf-9ae7-4771-bff0-089202b1ff1e
# ╠═d98a3a0a-947e-11ed-13a2-61b5b69b4df5
# ╠═0f10a758-e442-4cd8-88bc-d82d8de97ede
# ╠═a4207232-61eb-4da7-8629-1bcc670ab524
# ╠═722d4847-2458-4b23-b6a0-d1c321710a2a
# ╠═9d94bebb-fc41-482f-8759-cdf224ec71fb
# ╠═88720478-7f64-4852-8683-6be50793666a
