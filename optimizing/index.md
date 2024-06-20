+++
title = "Optimizing your code"
+++

\activate{}

# Optimizing your code

\toc

## Principles

\tldr{
The two fundamental principles for writing fast Julia code:

1. Ensure that **the compiler can infer the type** of every variable.
2. Avoid **unnecessary (heap) allocations**.
}

The compiler's job is to optimize and translate Julia code it into runnable [machine code](https://en.wikipedia.org/wiki/Machine_code).
If a variable's type cannot be deduced before the code is run, then the compiler won't generate efficient code to handle that variable.
We call this phenomenon "type instability".
Enabling type inference means making sure that every variable's type in every function can be deduced from the types of the function inputs alone.

A "heap allocation" (or simply "allocation") occurs when we create a new variable without knowing how much space it will require (like a `Vector` with flexible length).
Julia has a mark-and-sweep [garbage collector](https://docs.julialang.org/en/v1/devdocs/gc/) (GC), which runs periodically during code execution to free up space on the heap.
Execution of code is stopped while the garbage collector runs, so minimising its usage is important.

The vast majority of performance tips come down to these two fundamental ideas.
Typically, the most common beginner pitfall is the use of [untyped global variables](https://docs.julialang.org/en/v1/manual/performance-tips/#Avoid-untyped-global-variables) without passing them as arguments.
Why is it bad?
Because the type of a global variable can change outside of the body of a function, so it causes type instabilities wherever it is used.
Those type instabilities in turn lead to more heap allocations.

With this in mind, after you're done with the current page, you should read the [official performance tips](https://docs.julialang.org/en/v1/manual/performance-tips/): they contain some useful advice which is not repeated here for space reasons.

## Measurements

\tldr{Use BenchmarkTools.jl's `@benchmark` with a setup phase to get the most accurate idea of your code's performance. Use Chairmarks.jl as a faster alternative.}

The simplest way to measure how fast a piece of code runs is to use the `@time` macro, which returns the result of the code and prints the measured runtime and allocations.
Because code needs to be compiled before it can be run, you should first run a function without timing it so it can be compiled, and then time it:

```>time-example
sum_abs(vec) = sum(abs(x) for x in vec);
v = rand(100);
@time sum_abs(v); # Inaccurate, note the >99% compilation time
@time sum_abs(v); # Accurate
```

Using `@time` is quick but it has flaws, because your function is only measured once.
That measurement might have been influenced by other things going on in your computer at the same time.
In general, running the same block of code multiple times is a safer measurement method, because it diminishes the probability of only observing an outlier.

### BenchmarkTools

[BenchmarkTools.jl](https://github.com/JuliaCI/BenchmarkTools.jl) is the most popular package for repeated measurements on function executions.
Similarly to `@time`, BenchmarkTools offers `@btime` which can be used in exactly the same way but will run the code multiple times and provide an average.
Additionally, by using `$` to [interpolate external values](https://juliaci.github.io/BenchmarkTools.jl/stable/manual/#Interpolating-values-into-benchmark-expressions), you remove the overhead caused by global variables.

```>$-example
using BenchmarkTools
@btime sum_abs(v);
@btime sum_abs($v);
```

In more complex settings, you might need to construct variables in a [setup phase](https://juliaci.github.io/BenchmarkTools.jl/stable/manual/#Setup-and-teardown-phases) that is run before each sample.
This can be useful to generate a new random input every time, instead of always using the same input.

```>setup-example
my_matmul(A, b) = A * b;
@btime my_matmul(A, b) setup=(
    A = rand(1000, 1000); # use semi-colons between setup lines
    b = rand(1000)
);
```

For better visualization, the `@benchmark` macro shows performance histograms:

\advanced{
Certain computations may be [optimized away by the compiler]((https://juliaci.github.io/BenchmarkTools.jl/stable/manual/#Understanding-compiler-optimizations)) before the benchmark takes place.
If you observe suspiciously fast performance, especially below the nanosecond scale, this is very likely to have happened.
}

[Chairmarks.jl](https://github.com/LilithHafner/Chairmarks.jl) offers an alternative to BenchmarkTools.jl, promising faster benchmarking while attempting to maintain high accuracy and using an alternative syntax based on pipelines.

### Benchmark suites

While we previously discussed the importance of documenting breaking changes in packages using [semantic versioning](/sharing/index.md#versions-and-registration), regressions in performance can also be vital to track.
Several packages exist for this purpose:

- [PkgBenchmark.jl](https://github.com/JuliaCI/PkgBenchmark.jl) and its unmaintained but functional CI wrapper [BenchmarkCI.jl](https://github.com/tkf/BenchmarkCI.jl)
- [AirSpeedVelocity.jl](https://github.com/MilesCranmer/AirspeedVelocity.jl)
- [PkgJogger.jl](https://github.com/awadell1/PkgJogger.jl)

### Other tools

BenchmarkTools.jl works fine for relatively short and simple blocks of code (microbenchmarking).
To find bottlenecks in a larger program, you should rather use a [profiler](#profiling) or the package [TimerOutputs.jl](https://github.com/KristofferC/TimerOutputs.jl).
It allows you to label different sections of your code, then time them and display a table of grouped by label.

Finally, if you know a loop is slow and you'll need to wait for it to be done, you can use [ProgressMeter.jl](https://github.com/timholy/ProgressMeter.jl) or [ProgressLogging.jl](https://github.com/JuliaLogging/ProgressLogging.jl) to track its progress.

## Profiling

\tldr{
    Profiling can identify performance bottlenecks at function level, and graphical tools such as ProfileView.jl are the best way to use it.
}

### Sampling

Whereas a benchmark measures the overall performance of some code, a profiler breaks it down function by function to identify bottlenecks.
Sampling-based profilers periodically ask the program which line it is currently executing, and aggregate results by line or by function.
Julia offers two kinds: [one for runtime](https://docs.julialang.org/en/v1/stdlib/Profile/#lib-profiling) (in the module `Profile`) and [one for memory](https://docs.julialang.org/en/v1/stdlib/Profile/#Memory-profiling) (in the submodule `Profile.Allocs`).

These built-in profilers print textual outputs, but the result of profiling is best visualized as a flame graph.
In a flame graph, each horizontal layer corresponds to a specific level in the call stack, and the width of a tile shows how much time was spent in the corresponding function.
Here's an example:

![flamegraph](https://github.com/pfitzseb/ProfileCanvas.jl/raw/main/assets/flamegraph.png)

### Visualization tools

The packages [ProfileView.jl](https://github.com/timholy/ProfileView.jl) and [PProf.jl](https://github.com/JuliaPerf/PProf.jl) both allow users to record and interact with flame graphs.
ProfileView.jl is simpler to use, but PProf is more featureful and is based on [pprof](https://github.com/google/pprof), an external tool maintained by Google which applies to more than just Julia code.
Here we only demonstrate the former:

```julia profileview-example
using ProfileView
@profview do_work(some_input)
```

\vscode{
    Calling `@profview do_work(some_input)` in the integrated Julia REPL will open an interactive flame graph, similar to ProfileView.jl but without requiring a separate package.
}

To integrate profile visualisations into environments like Jupyter and Pluto, use [ProfileSVG.jl](https://github.com/kimikage/ProfileSVG.jl) or [ProfileCanvas.jl](https://github.com/pfitzseb/ProfileCanvas.jl), whose outputs can be embedded into a notebook.

No matter which tool you use, if your code is too fast to collect samples, you may need to run it multiple times in a loop.

\advanced{
    To visualize memory allocation profiles, use PProf.jl or VSCode's `@profview_allocs`. 
    A known issue with the allocation profiler is that it is not able to determine the type of every object allocated, instead `Profile.Allocs.UnknownType` is shown instead.
    Inspecting the call graph can help identify which types are responsible for the allocations.
}

## Type stability

\tldr{Use JET.jl to automatically detect type instabilities in your code, and `@code_warntype` or Cthulhu.jl to do so manually. DispatchDoctor.jl can help prevent them altogether.}

For a section of code to be considered type stable, the type inferred by the compiler must be "concrete", which means that the size of memory that needs to be allocated to store its value is known at compile time.
Types declared abstract with `abstract type` are not concrete and neither are [parametric types](https://docs.julialang.org/en/v1/manual/types/#Parametric-Types) whose parameters are not specified:

```>isconcretetype-example
isconcretetype(Any)
isconcretetype(AbstractVector)
isconcretetype(Vector) # Shorthand for `Vector{T} where T`
isconcretetype(Vector{Real})
isconcretetype(eltype(Vector{Real}))
isconcretetype(Vector{Int64})
```

\advanced{
`Vector{Real}` is concrete despite `Real` being abstract for [subtle typing reasons](https://docs.julialang.org/en/v1/manual/types/#man-parametric-composite-types) but it will still be slow in practice because the type of its elements is abstract.
}

<!-- thanks Frames White: https://stackoverflow.com/a/58132532 -->
While type-stable function calls compile down to fast `GOTO` statements, type-unstable function calls generate code that must read the list of all methods for a given operation and find the one that matches.
This phenomenon called "dynamic dispatch" prevents further optimizations.

Type-stability is a fragile thing: if a variable's type cannot be inferred, then the types of variables that depend on it may not be inferrable either.
As a first approximation, most code should be type-stable unless it has a good reason not to be.

### Detecting instabilities

The simplest way to detect an instability is with the builtin macro [`@code_warntype`](https://docs.julialang.org/en/v1/manual/performance-tips/#man-code-warntype):
The output of `@code_warntype` is difficult to parse, but the key takeaway is the return type of the function's `Body`: if it is an abstract type, like `Any`, something is wrong.
In a normal Julia REPL, such cases would show up colored in red as a warning.

```!interactiveutils
using InteractiveUtils  # hide
```

```>
function put_in_vec_and_sum(x)
    v = []
    push!(v, x)
    return sum(v)
end;

@code_warntype put_in_vec_and_sum(1)
```

Unfortunately, `@code_warntype` is limited to one function body: calls to other functions are not expanded, which makes deeper type instabilities easy to miss.
That is where [JET.jl](https://github.com/aviatesk/JET.jl) can help: it provides [optimization analysis](https://aviatesk.github.io/JET.jl/stable/optanalysis/) aimed primarily at finding type instabilities.
While [test integrations](https://aviatesk.github.io/JET.jl/stable/optanalysis/#optanalysis-test-integration) are also provided, the interactive entry point of JET is the `@report_opt` macro.

```>JET_opt
using JET
@report_opt put_in_vec_and_sum(1)
```

\vscode{The Julia extension features a [static linter](https://www.julia-vscode.org/docs/stable/userguide/linter/), and runtime diagnostics with JET can be automated to run periodically on your codebase and show any problems detected.}

[Cthulhu.jl](https://github.com/JuliaDebug/Cthulhu.jl) exposes the `@descend` macro which can be used to interactively "step through" lines of the corresponding typed code, and "descend" into a particular line if needed.
This is akin to repeatedly calling `@code_warntype` deeper and deeper into your functions, slowly succumbing to the madness...
We cannot demonstrate it on a static website, but the [video example](https://www.youtube.com/watch?v=pvduxLowpPY) is a good starting point.

### Fixing instabilities

The Julia manual has a collection of tips to [improve type inference](https://docs.julialang.org/en/v1.12-dev/manual/performance-tips/#Type-inference).

A more direct approach is to error whenever a type instability occurs: the macro `@stable` from [DispatchDoctor.jl](https://github.com/MilesCranmer/DispatchDoctor.jl) allows exactly that.

## Memory management

After ensuring type stability, one should try to reduce the number of heap allocations a program makes.
Again, the Julia manual has a series of tricks related to [arrays and allocations](https://docs.julialang.org/en/v1.12-dev/manual/performance-tips/#Memory-management-and-arrays) which you should take a look at.

And again, you can also choose to error whenever an allocation occurs, with the help of [AllocCheck.jl](https://github.com/JuliaLang/AllocCheck.jl).
By annotating a function with `@check_allocs`, if the function is run and the compiler detects that it might allocate, it will throw an error.
Alternatively, to ensure that non-allocating functions never regress in future versions of your code, you can write a test set to check allocations by providing the function and a concrete type-signature.

```julia AllocCheck
@testset "non-allocating" begin
    @test isempty(AllocCheck.check_allocs(my_func, (Float64, Float64)))
end
```

## Precompilation

- [PrecompileTools.jl](https://github.com/JuliaLang/PrecompileTools.jl)
- [PackageCompiler.jl](https://github.com/JuliaLang/PackageCompiler.jl)
- [StaticCompiler.jl](https://github.com/tshort/StaticCompiler.jl)
- [SnoopCompile.jl](https://github.com/timholy/SnoopCompile.jl)
- [compiling in VSCode](https://www.julia-vscode.org/docs/stable/userguide/compilesysimage/)

## Parallelism

- [distributed vs. multithreading](https://docs.julialang.org/en/v1/manual/parallel-computing/)
- [OhMyThreads.jl](https://github.com/JuliaFolds2/OhMyThreads.jl)

## SIMD / GPU

- [LoopVectorization.jl](https://github.com/JuliaSIMD/LoopVectorization.jl) (deprecated in 1.11)
- [Tullio.jl](https://github.com/mcabbott/Tullio.jl)
- [KernelAbstractions.jl](https://github.com/JuliaGPU/KernelAbstractions.jl)

## Efficient types

- [StaticArrays.jl](https://github.com/JuliaArrays/StaticArrays.jl)
- [Dictionaries.jl](https://github.com/andyferris/Dictionaries.jl)