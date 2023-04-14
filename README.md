# DynamicHMCModels


| **Project Status**                                                               |  **Documentation**                                                               | **Build Status**                                                                                |
|:-------------------------------------------------------------------------------:|:-------------------------------------------------------------------------------:|:-----------------------------------------------------------------------------------------------:|
|![][project-status-img] |
## Introduction

This package contains Julia versions of the mcmc models contained in the R package "rethinking" associated with the book [Statistical Rethinking](https://xcelab.net/rm/statistical-rethinking/) by Richard McElreath. It is part of the [StatisticalRethinkingJulia](https://github.com/StatisticalRethinkingJulia) Github organization of packages.

This package implements the models using [DynamicHMC](https://github.com/tpapp/DynamicHMC.jl).

## Note

Converted to DynamicHMC 3.0. 

This is a breaking change for many reasons. E.g., DynamicHMC.jl and related packages have been improved, MonteCarloMeasurements.jl (used for quick summaries) has been replaced by RegressionAndOtherStories.jl, MCMCChains.jl has been dropped (I would like to use InferenceObjects.jl as a replacement) and all models will be demonstrated using Pluto.

Note that after `using DynamicHMCModels` most dependencies are available with 2 exceptions: BenchmarkTools and RegressionAndOtherStories.

## Acknowledgements

Tamas Papp has been very helpful during the development of the DynamicHMC versions of the models.

## Questions and issues

Questions and contributions are very welcome, as are feature requests and suggestions. Please open an [issue][issues-url] if you encounter any problems or have a question.

[issues-url]: https://github.com/StatisticalRethinkingJulia/DynamicHMCModels.jl/issues

[project-status-img]: https://img.shields.io/badge/lifecycle-wip-orange.svg

