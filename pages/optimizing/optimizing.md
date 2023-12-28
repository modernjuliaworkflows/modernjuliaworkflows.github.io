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
\tldr{Use BenchmarkTools.jl's `@benchmark` with a setup phase to get the best overview of performance or `@btime` as a drop in for `@time`.}

The simplest way to measure how fast a piece of code runs is to use the `@time` macro, which returns the result of the code and prints time, allocation, and compilation information. Because of how Julia's JIT compiler works, you should first run a function and then time it:

```julia
f(vec) = sum(abs, vec)
v = rand(100)
@time f(v)
@time f(v)
```

Above, we can see that the first invocation of `@time` was dominated by the compilation time of `f`, while the second only involved a single allocation of 16 bytes.
Below, in the BenchmarkTools section we will see that this single allocation is actually a red herring.
One consequence of a large number of heap allocations is that the [GC](https://en.wikipedia.org/wiki/Tracing_garbage_collection) (garbage collector) will need to run to clear up the program's memory so it can be reused.
This can heavily impact performance and so `@time` also shows how much of the time (if any) was taken up by the GC.

This method of running `@time` is quick but has flaws because your code is only timed once.
For example, just because the GC wasn't invoked one time, doesn't mean it won't the next.
This combined with the varying background processes running on a computer means that running the same line of code multiple times can vary in performance.
Furthermore, while a function may run well on certain data, for a more complete picture the function should be tested on many different inputs relevant to how it will be used.
A commonly used tool to do both of these is [BenchmarkTools.jl](https://github.com/JuliaCI/BenchmarkTools.jl).

### BenchmarkTools

Similarly to `@time`, BenchmarkTools offers `@btime` which can be used in exactly the same way but will run the code multiple times and provide an average.
Additionally, by using `$` to interpolate values, you can be sure that you are timing __only__ the execution and not the setup or construction of the code in question.

```julia
@btime f(v)
@btime f($v)
```

Now that we're interpolating our argument `v`, we can see that our function `f` is completely non-allocating and so its performance won't be slowed down by GC invocations.

Note that you can also construct variables and interpolate them:

```julia
@btime f($(rand(Int64, 1000)))
```

However, doing so will mean that any randomness will be the same for every run!
Furthermore, constructing and interpolating multiple variables can get messy.
As such, the best way to run a benchmark is to construct variables in a `setup` phase.
Note that variables constructed this way should not be interpolated in as this indicates that BenchmarkTools should search for a global variable with that name.

```julia
my_matmul(A, b) = A * b
@btime my_matmul(A, b) setup=(
    # use semi-colons inside a setup block to start new lines
    A = rand(1000, 1000);
    b = rand(1000)
)
```

A setup phase means that you get a full overview of a function's performance as not only are you running the function many times, each run also has a different input.

For the best visualisation of performance, the `@benchmark` macro is also provided which shows performance histograms:
```julia
@benchmark my_matmul(A, b) setup=(
    A = rand(1000, 1000);
    b = rand(1000)
)
```

Finally, it's worth noting that certain computations may be optimized away by the compiler before the benchmark takes place, resulting in suspicuously fast performance, however the [details of this](https://juliaci.github.io/BenchmarkTools.jl/stable/manual/#Understanding-compiler-optimizations) are beyond the scope of this post and most users should not worry at all about this.

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
