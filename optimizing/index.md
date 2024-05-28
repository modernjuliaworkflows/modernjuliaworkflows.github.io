+++
title = "Optimizing your code"
+++

\activate{}

# Optimizing your code

\toc

## Principles

* [performance tips](https://docs.julialang.org/en/v1/manual/performance-tips/)

## Measurements

* [ProgressMeter.jl](https://github.com/timholy/ProgressMeter.jl)
* [BenchmarkTools.jl](https://github.com/JuliaCI/BenchmarkTools.jl)
* [Chairmarks.jl](https://github.com/LilithHafner/Chairmarks.jl)
* [TimerOutputs.jl](https://github.com/KristofferC/TimerOutputs.jl)

## Benchmark suites

* [PkgBenchmark.jl](https://github.com/JuliaCI/PkgBenchmark.jl)
* [BenchmarkCI.jl](https://github.com/tkf/BenchmarkCI.jl) (unmaintained)
* [AirSpeedVelocity.jl](https://github.com/MilesCranmer/AirspeedVelocity.jl)
* [PkgJogger.jl](https://github.com/awadell1/PkgJogger.jl)

## Profiling

* [built-in profiler](https://docs.julialang.org/en/v1/manual/profile/) and [allocation profiler](https://docs.julialang.org/en/v1/stdlib/Profile/#Memory-profiling)
* [ProfileView.jl](https://github.com/timholy/ProfileView.jl) / [ProfileSVG.jl](https://github.com/kimikage/ProfileSVG.jl)
* [PProf.jl](https://github.com/JuliaPerf/PProf.jl)
* [profiling in VSCode](https://www.julia-vscode.org/docs/stable/userguide/profiler/)

## Type stability

* [Cthulhu.jl](https://github.com/JuliaDebug/Cthulhu.jl)
* [JET.jl](https://github.com/aviatesk/JET.jl)
* [linting in VSCode](https://www.julia-vscode.org/docs/stable/userguide/linter/)
* [DispatchDoctor.jl](https://github.com/MilesCranmer/DispatchDoctor.jl)

## Memory management

* [AllocCheck.jl](https://github.com/JuliaLang/AllocCheck.jl)
* [BangBang.jl](https://github.com/JuliaFolds2/BangBang.jl)

## Precompilation

* [PrecompileTools.jl](https://github.com/JuliaLang/PrecompileTools.jl)
* [PackageCompiler.jl](https://github.com/JuliaLang/PackageCompiler.jl)
* [StaticCompiler.jl](https://github.com/tshort/StaticCompiler.jl)
* [SnoopCompile.jl](https://github.com/timholy/SnoopCompile.jl)
* [compiling in VSCode](https://www.julia-vscode.org/docs/stable/userguide/compilesysimage/)

## Parallelism

* [distributed vs. multithreading](https://docs.julialang.org/en/v1/manual/parallel-computing/)
* [OhMyThreads.jl](https://github.com/JuliaFolds2/OhMyThreads.jl)

## SIMD / GPU

* [LoopVectorization.jl](https://github.com/JuliaSIMD/LoopVectorization.jl) (deprecated in 1.11)
* [Tullio.jl](https://github.com/mcabbott/Tullio.jl)
* [KernelAbstractions.jl](https://github.com/JuliaGPU/KernelAbstractions.jl)

## Efficient types

* [StaticArrays.jl](https://github.com/JuliaArrays/StaticArrays.jl)
* [Dictionaries.jl](https://github.com/andyferris/Dictionaries.jl)
