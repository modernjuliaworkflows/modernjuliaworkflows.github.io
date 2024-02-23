+++
title = "Optimizing your code"
+++

\activate{}

# Optimizing your code

\toc

## Principles

All tips to writing performant Julia code can be derived from two fundamental ideas:
1. Ensure that type of every variable can be concretely inferred every time each is used.
2. Avoid unnecessary heap allocations.

By "concretely", we mean that the type inferred by the compiler is concrete, this means that its size in memory is known at compile time.
Types declared abstract with `abstract type` are not concrete and neither are [parametric types](https://docs.julialang.org/en/v1/manual/types/#Parametric-Types) whose parameters are not specified:
```>isconcretetype-example
isconcretetype(AbstractVector)
isconcretetype(Vector) # Shorthand for `Vector{T} where T`
isconcretetype(Vector{Real})
isconcretetype(Vector{Int64})
```

\advanced{
`Vector{Real}` is concrete despite `Real` being abstract because all parametric types besides tuples are [invariant](https://docs.julialang.org/en/v1/manual/types/#man-parametric-composite-types) in their parameters (as opposed to covariant or contravariant).
Because `Vector{Real}` therefore can't be subtyped, it must have a concrete implementation which, in Julia's case, is as a vector of pointers to individually allocated `Real` objects.
This implementation detail (a pointer to pointers) also explains part of the reason why `Vector{Real}` is slow, the other being a lack of concrete compile-time specialisation on the elements of the vector.
}

Before running any piece of code, the Julia compiler tries to determine the most specialised method it can use to ensure that the code runs as fast as possible e.g. 1+1 faster than 1 floatingpoint+ 1.
For each variable, including a function output, contained in a block of code, if all pieces of information necessary to determine its type are type inferrable, then so is the variable in question.
This means that if a variable cannot be inferred, then no variables that depend on it in any way can be either.
<!-- thanks Frames White: https://stackoverflow.com/a/58132532 -->
While type stable function calls compile down to fast goto statements, unstable function calls compile to code that reads the list of all methods for that function and find the one that matches.
This phenomenon called "dynamic dispatch" essentially prevents further optimizations via [inlining](https://en.wikipedia.org/wiki/Inline_expansion).

A heap allocation occurs when an object is to be allocated, but how much space to allocate cannot be inferred from its type.
Its counterpart is the [stack allocation](https://en.wikipedia.org/wiki/Stack-based_memory_allocation), which will only be performed if the object being allocated has a known size *and* its data cannot be modified after allocation i.e. the data is [immutable](https://en.wikipedia.org/wiki/Immutable_object).
The benefit of these stringent rules is that stack allocations and deallocations are so fast that they are considered negligible by Julia's benchmarking tools (detailed below) and are not included in the total count of allocations.
On the other hand, objects on the heap cannot be so heavily optimized by the compiler as the data and its size may change.
In order to manage the deallocation of heap objects after their usage, Julia has a [mark-and-sweep](https://en.wikipedia.org/wiki/Tracing_garbage_collection#Copying_vs._mark-and-sweep_vs._mark-and-don't-sweep) [garbage collector](https://docs.julialang.org/en/v1/devdocs/gc/), which runs periodically during code execution to free up space so that other objects can be allocated.
The necessity of the garbage collector combined with the lack of optimizations means that heap allocations, while incredibly useful and oftentimes necessary, should be avoided if possible.

Paraphrasing the Julia manual's [performance tips](https://docs.julialang.org/en/v1/manual/performance-tips/#Measure-performance-with-[@time](@ref)-and-pay-attention-to-memory-allocation) section: the most common causes of the "unnecessary" heap allocations are type-instability and unintended temporary arrays.
The example function below, which calculates a weighted mean and returns its positive part, subtly exhibits both of these issues:

```>heap-allocations-example
function positive_weighted_mean(values, weights)
    result = sum(weights .* values) / sum(weights)
    return result > 0 ? result : 0
end
```

The unintended heap allocation comes from the elementwise product `weights .* values`, which stores its result in a temporary array which is immediately used by `sum`.
As the result of the product isn't needed anywhere else, this is an example of an unnecessary allcoation.
There are a number of ways to rewrite this specific line to avoid allocating an intermediate vector: both `transpose(weights) * values` and `sum(splat(*), zip(weights, values))` have similar performance.
More important than this specific fix is more generally that both methods avoid instantiating the intermediate product vector by being more specific about exactly what the code should do.

The type instability is a result of the final line `result > 0 ? result : 0`.
What type does the function return?
Sometimes it returns the integer `0`, whereas other times it returns `result`, which is, in most cases, a `Float64`.
This dependence on run-time value as opposed to compile-time type results in the instability, causing an additional heap allocation which slows the function down further.
We can fix this instability simply by replacing the final `0` with `zero(result)`, which returns the zero element of whatever type `result` happens to be.

* [performance tips](https://docs.julialang.org/en/v1/manual/performance-tips/)

## Measurements

* [ProgressMeter.jl](https://github.com/timholy/ProgressMeter.jl)
* [BenchmarkTools.jl](https://github.com/JuliaCI/BenchmarkTools.jl)
\tldr{Use BenchmarkTools.jl's `@benchmark` with a setup phase to get the best overview of performance or `@btime` as a drop in for `@time`.}

The simplest way to measure how fast a piece of code runs is to use the `@time` macro, which returns the result of the code and prints time, allocation, and compilation information. Because of how Julia's JIT compiler works, you should first run a function and then time it:

```>time-example
sum_abs(vec) = sum(abs, vec)
v = rand(100)
@time sum_abs(v)
@time sum_abs(v)
```

Above, we can see that the first invocation of `@time` was dominated by the compilation time of `sum_abs`, while the second only involved a single allocation of 16 bytes.
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

```>$-example
using BenchmarkTools
@btime sum_abs(v)
@btime sum_abs($v)
```

Now that we're interpolating our argument `v`, we can see that our function `sum_abs` is completely non-allocating and so its performance won't be slowed down by GC invocations.

Note that you can also construct variables and interpolate them:

```>$-randomness-example
@btime sum_abs($(rand(10)))
```

However, doing so will mean that any randomness will be the same for every run!
Furthermore, constructing and interpolating multiple variables can get messy.
As such, the best way to run a benchmark is to construct variables in a `setup` phase.
Note that variables constructed this way should not be interpolated in as this indicates that BenchmarkTools should search for a global variable with that name.

```>setup-example
my_matmul(A, b) = A * b;
@btime my_matmul(A, b) setup=(
    # use semi-colons inside a setup block to start new lines
    A = rand(1000, 1000);
    b = rand(1000)
)
```

A setup phase means that you get a full overview of a function's performance as not only are you running the function many times, each run also has a different input.

For the best visualisation of performance, the `@benchmark` macro is also provided which shows performance histograms:
```>benchmark-example
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

## Efficient types

* [StaticArrays.jl](https://github.com/JuliaArrays/StaticArrays.jl)
* [Dictionaries.jl](https://github.com/andyferris/Dictionaries.jl)