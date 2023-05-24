### A Pluto.jl notebook ###
# v0.19.25

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
    "~/.julia/dev/DynamicHMCModels/notebooks/bernoulli_example.jl",
    "~/.julia/dev/DynamicHMCModels/notebooks/linear_regression_example.jl",
    "~/.julia/dev/DynamicHMCModels/notebooks/m2_1d.jl",
    "~/.julia/dev/DynamicHMCModels/notebooks/m4_1d.jl",
	
	"~/.julia/dev/DynamicHMCModels/notebooks/Maintenance/Notebook-to-reset-DynamicHMCModels-jl-notebooks.jl"
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
