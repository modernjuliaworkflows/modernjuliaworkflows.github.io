+++
title = "Optimizing your code"
+++

\activate{}

# Optimizing your code

\toc

## Principles

All tips to writing performant Julia code can be derived from two fundamental ideas:
1. Ensure that type of every variable can be unambiguously inferred every time each is used.
2. Avoid unnecessary heap allocations.

to understand these two ideas, we have to dig into how computers work and how the julia compiler works with computers.

Put an explanation of heap and stack allocations here.

Before running any piece of code, the Julia compiler tries to determine the most specialised method it can use to ensure that the code runs as fast as possible e.g. 1+1 faster than 1 floatingpoint+ 1.
For each variable, including a function output, contained in a block of code, if all pieces of information necessary to determine its type are type inferrable, then so is the variable in question.
This means that if a variable cannot be inferred, then no variables that depend on it in any way can be either.
<!-- thanks Frames White: https://stackoverflow.com/a/58132532 -->
While type stable function calls compile down to fast goto statements, unstable function calls compile to code that reads the list of all methods for that function and find the one that matches.
This phenomenon called "dynamic dispatch" essentially prevents further optimizations via [inlining](https://en.wikipedia.org/wiki/Inline_expansion).

* [performance tips](https://docs.julialang.org/en/v1/manual/performance-tips/)

## Measurements

The simplest way to measure how fast a piece of code runs is to use the `@time` macro. Because of how Julia's JIT compiler works, you should first run a function and then time it:

example

Notes:
- The macro also tells you how how many allocations and how large it was taken.
- Relatedly, you also see how much of the time was taken up by the GC and by compilation. High GC usage can indicate some unnecessary heap allocations e.g. in a hot loop

This method has flaws because you're only timing it once: lots of stuff goes on in the background of a computer and data may change so you ideally want a lot of samples.
Furthermore, you may want to measure the performance over various inputs
### BenchmarkTools
[BenchmarkTools.jl](https://github.com/JuliaCI/BenchmarkTools.jl)
Talk about setup phase and then mention the importance of interpolation.
Finally, mention about how sometimes things can get optimised away before they are run.

<!-- I (Martin) have never used either of these, someone with experience can write here? -->
* [TimerOutputs.jl](https://github.com/KristofferC/TimerOutputs.jl)
* [PkgBenchmark.jl](https://github.com/JuliaCI/PkgBenchmark.jl)

## Profiling

* [built-in](https://docs.julialang.org/en/v1/manual/profile/)
* [ProfileView.jl](https://github.com/timholy/ProfileView.jl) / [ProfileSVG.jl](https://github.com/kimikage/ProfileSVG.jl)
* [profiling in VSCode](https://www.julia-vscode.org/docs/stable/userguide/profiler/)

### PProf
[PProf](https://github.com/JuliaPerf/PProf.jl)

This code has changed my life for the better, by far the best way to profile allocations along with using Cthulhu
```julia
using PProf
using Profile
begin
    Profile.Allocs.clear()
    f(arg1, arg2)
    Profile.Allocs.@profile sample_rate=1 f(arg1, arg2)
    PProf.Allocs.pprof(from_c=false)
end

```

## Type stability

* [Cthulhu.jl](https://github.com/JuliaDebug/Cthulhu.jl)
* [JET.jl](https://github.com/aviatesk/JET.jl)
* [linting in VSCode](https://www.julia-vscode.org/docs/stable/userguide/linter/)

## Precompilation

* [PrecompileTools.jl](https://github.com/JuliaLang/PrecompileTools.jl)
* [PackageCompiler.jl](https://github.com/JuliaLang/PackageCompiler.jl)
<!-- * [StaticCompiler.jl](https://github.com/tshort/StaticCompiler.jl)  I don't think this belongs here-->
* [SnoopCompile.jl](https://github.com/timholy/SnoopCompile.jl)
* [compiling in VSCode](https://www.julia-vscode.org/docs/stable/userguide/compilesysimage/)

## Parallelism

* [distributed vs. multithreading](https://docs.julialang.org/en/v1/manual/parallel-computing/)
* [ThreadsX.jl](https://github.com/tkf/ThreadsX.jl)
* [FLoops.jl](https://github.com/JuliaFolds/FLoops.jl)

## SIMD / GPU

* [LoopVectorization.jl](https://github.com/JuliaSIMD/LoopVectorization.jl)
* [Tullio.jl](https://github.com/mcabbott/Tullio.jl)
* [KernelAbstractions.jl](https://github.com/JuliaGPU/KernelAbstractions.jl)

## Miscellaneous

* [StaticArrays.jl](https://github.com/JuliaArrays/StaticArrays.jl)
