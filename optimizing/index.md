+++
title = "Optimizing your code"
+++

```! run_bad_functions
# hideall
using Chairmarks
function bad_function(y)
    a = x + y
    b = x - y
    return a ./ b
end
function better_function(x, y)
    a = x + y
    b = x - y
    return a ./ b
end
function no_better_function(x, y)    
    return (x + y) ./ (x - y)
end
function best_function!(c, x, y)
     @. c = (x + y) ./ (x - y)
    return nothing
end
function best_function(x, y)
    c = zeros(size(x))
    best_function!(c, x, y)
    return c
end
```

\activate{}

# Optimizing your code

\toc

## Principles

All tips to writing performant Julia code can be derived from two fundamental ideas:
1. Ensure that the compiler can infer the type of every variable so optimizations be performed.
2. Avoid unnecessary heap allocations which slow the code down.

The compiler's job is to optimize and translate Julia code it into runnable [machine code](https://en.wikipedia.org/wiki/Machine_code).
If some information about a variable's type isn't available to the compiler, for example because the [return type of a function is value-dependent](https://docs.julialang.org/en/v1/manual/performance-tips/#Write-%22type-stable%22-functions), then it cannot safely perform its most powerful optimizations as it cannot satisfy assumptions required for the optimizations to be performed. For more information see [below](#type_stability).

A "heap" allocation occurs whenever a variable is allocated whose type doesn't contain enough information to know exactly how much space is required to store all of its data.
An example of this is `Vector{Int}`, which doesn't contain information about how many elements the vector has.
In order to manage the deallocation of objects after their usage, Julia has a [mark-and-sweep](https://en.wikipedia.org/wiki/Tracing_garbage_collection#Copying_vs._mark-and-sweep_vs._mark-and-don't-sweep) [garbage collector](https://docs.julialang.org/en/v1/devdocs/gc/), which runs periodically during code execution to free up space so that other objects can be allocated.
Execution of code is stopped while the garbage collector runs, so minimising its usage is important.

In the example below, we break both fundamental principles.

```julia break-rules-example
function bad_function(y)
    a = x + y
    b = x - y
    return a ./ b
end
```

While `y` is correctly passed as an argument to `bad_function`, `x` isn't, and because it is an [untyped global variable](https://docs.julialang.org/en/v1/manual/performance-tips/#Avoid-untyped-global-variables), its type must be inferred each time the function is run, which results in an allocation.
This could be solved by redefining `bad_function` to accept both `x` and `y` as arguments.
``` julia remove-untyped-global
function better_function(x, y)
    a = x + y
    b = x - y
    return a ./ b
end
```

Moreover, even if the user only cares about the value of `c` the variables `a` and `b` are still heap allocated.
Notably, this _cannot_ simply be improved by writing the function as

```julia no_better
function no_better_function(x, y)    
    return (x + y) ./ (x - y)
end
```

because Julia allocates intermediate values in the same line.
The way to avoid intermediate allocations is to reuse memory as much as possible.
Typically, the simplest way to do this is to "fuse" operations through broadcasting with `@.`

```julia fuse-operations
function best_function(x, y)
    return @. (x + y) ./ (x - y)
end
```

Finally, a common design pattern in Julia packages to achieve convenience and offer the best performance to end users is to write a non-allocating, in-place version of a function which performs all of the computation, and an allocating version which simply preallocates memory, and calls into the in-place function:

```julia
function best_function!(c, x, y)
     @. c = (x + y) ./ (x - y)
    return nothing
end

function best_function(x, y)
    c = zeros(size(x))
    best_function!(c, x, y)
    return c
end
```

```> timings
using BenchmarkTools: @btime
x = rand(100); y = rand(100); c = zeros(100);
@btime bad_function(y);
@btime better_function(x, y);
@btime best_function(x, y);
@btime best_function!(c, x, y)
```

Any specific performance tip, either those found in the [manual](https://docs.julialang.org/en/v1/manual/performance-tips/) or elsewhere, will ultimately come down to these two fundamental ideas.
For example, it's recommended to [__Avoid untyped global variables__](https://docs.julialang.org/en/v1/manual/performance-tips/#Avoid-untyped-global-variables).
Why? Because the type of a global variable could change, so it causes type instability wherever it is used without being passed to a function as an argument.
Why might you want to [preallocate outputs](https://docs.julialang.org/en/v1/manual/performance-tips/#Pre-allocating-outputs) and [fuse vectorized opterations](https://docs.julialang.org/en/v1/manual/performance-tips/#More-dots:-Fuse-vectorized-operations)? To minimise heap allocations.

## Measurements

\tldr{Use BenchmarkTools.jl's `@benchmark` with a setup phase to get the most accurate idea of your code's performance. Use Chairmarks.jl as a faster alternative.}

The simplest way to measure how fast a piece of code runs is to use the `@time` macro, which returns the result of the code and prints time, allocation, and compilation information.
Because code needs to be compiled before it can be run, you should first run a function without timing it so it can be compiled, and _then_ time it:

```>time-example
sum_abs(vec) = sum(abs, vec)
v = rand(100)
@time sum_abs(v) # Inaccurate, >99% note compilation time
@time sum_abs(v) # Accurate
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
```julia benchmark-example
@benchmark my_matmul(A, b) setup=(
    A = rand(1000, 1000);
    b = rand(1000)
)
BenchmarkTools.Trial: 3870 samples with 1 evaluation.
 Range (min … max):  133.584 μs …  3.278 ms  ┊ GC (min … max): 0.00% … 0.00%
 Time  (median):     206.958 μs              ┊ GC (median):    0.00%
 Time  (mean ± σ):   217.264 μs ± 89.229 μs  ┊ GC (mean ± σ):  0.00% ± 0.00%

           ▁▆█▇▃▃▁▃▄▅▁                                          
  ▂▃▃▃▃▃▄▄▅███████████▆▅▄▄▄▃▃▃▃▂▂▂▂▂▂▂▂▂▂▁▂▁▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂ ▃
  134 μs          Histogram: frequency by time          439 μs <

 Memory estimate: 8.00 KiB, allocs estimate: 1.
```

Finally, it's worth noting that certain computations may be optimized away by the compiler before the benchmark takes place, resulting in suspicuously fast performance, however the [details of this](https://juliaci.github.io/BenchmarkTools.jl/stable/manual/#Understanding-compiler-optimizations) are beyond the scope of this post and most users should not worry at all about this.

### Chairmarks.jl
[This package](https://github.com/LilithHafner/Chairmarks.jl) offers an alternative to BenchmarkTools.jl, promising _significantly_ faster benchmarking while attempting to maintain high accuracy and using an alternative syntax based on pipelines.

```julia chairmarks-example
# Generate a random vector, sort it, then check if it's sorted
@b rand(1000) sort! issorted(_) || error()
```

These pipelines ensure that you can not only benchmark your code, but that your code returns the result expected.

### Other tools

The setup above is great for individual lines of code, but get insight into which parts of a larger program are bottlenecks it is recommended to use a [profiler](#profiling) or a lightweight tool like [TimerOutputs.jl](https://github.com/KristofferC/TimerOutputs.jl).
This package allows you to label different sections of your code, then time them and view the performance summarised by label.

Finally, if you know a section is slow and you'll need to wait for it to be done, you can use [ProgressMeter.jl](https://github.com/timholy/ProgressMeter.jl) to visualise how long it will take.


## Benchmark suites

While we previously discussed the importance of documenting breaking changes in packages using [semantic versioning](/sharing/index.md#versions-and-registration), regressions in performance can also be vital to track.

Package benchmarks are typically stored in `MyPackage/benchmark/benchmarks.jl` and the file typically defines a 
  1. Load BenchmarkTools
  2. Initialise a `const` `BenchmarkGroup()` called `SUITE` by convention.
  3. Use `@benchmarkable` to define named benchmarks as key value pairs of `SUITE`

```julia
using BenchmarkTools

const SUITE = BenchmarkGroup()

#TODO Insert example of a suite of benchmarks
```

To run this suite manually use [PkgBenchmark.jl](https://github.com/JuliaCI/PkgBenchmark.jl)

However, catching regressions is much easier when it is automated which is what tools like [AirSpeedVelocity.jl](https://github.com/MilesCranmer/AirspeedVelocity.jl) and [PkgJogger.jl](https://github.com/awadell1/PkgJogger.jl) aim to help with.

## Profiling
\tldr{
    The built-in [Profile](https://docs.julialang.org/en/v1/stdlib/Profile/#lib-profiling) module and its [`Allocs`](https://docs.julialang.org/en/v1/stdlib/Profile/#Memory-profiling) submodule can help you find performance bottlenecks.
    Visualise the results interactively with [PProf.jl](https://github.com/JuliaPerf/PProf.jl), or with [ProfileSVG.jl](https://github.com/kimikage/ProfileSVG.jl) if you program in Jupyter/Pluto notebooks.
}

Whereas a benchmark measures the overall performance of some code, a profiler breaks this data down function by function.
This allows the user to identify sections of code responsible for performance bottlenecks, and shows precisely which functions take up most of the running time.
As with benchmarks, there are a number of ways to both collect and visualise this performance data.
Julia features a built-in [sampling profiler](https://en.wikipedia.org/wiki/Profiling_(computer_programming)#Statistical_profilers), a tool that periodically captures a snapshot of what the program is doing.

Let's define a few inefficient functions and then use a few different tools to identify the lines causing trouble.

```julia profile-functions
slow_relu(x) = x > 0 ? x : 0 # Don't define ReLU like this.

function do_work(xs)
    ans = []
    for x in xs
        push!(ans, slow_relu(x))
    end
    return ans
end
```

\vscode{
    Calling `@profview do_work(xs)` will open an interactive flame graph of the profiled stackframes in a split screen. Note that, due to function name overlap, importing ProfileView in a VSCode session causes namespace conflicts which can be resolved by writing `ProfileView.@profview`.
}

The tools [ProfileView.jl](https://github.com/timholy/ProfileView.jl) and [PProf.jl](https://github.com/JuliaPerf/PProf.jl) both allow users to produce and interact with CPU flamegraphs, in which functions that were more frequently sampled take up a wider space in the chart.
ProfileView.jl is simpler to use, but PProf is more featureful and is based on `pprof`, an external tool maintained by employees at Google which can be used to profile more than just Julia code.
The code example below demonstrates the usage differences between the packages:

```julia profileview-example
xs = rand(100_000) .- 0.5;

do_work(xs) # Run once to precompile

# ProfileView.jl
using ProfileView
@profview do_work(xs)
```

ProfileView exports `@profileview` which combines the collection and visualisation step in one, opening the flamegraph in a separate window.

```julia pprof-example
# PProf.jl
using Profile #stdlib
using PProf
begin 
    Profile.clear()
    @profile do_work(xs)
    pprof()
end
```

On the other hand PProf.jl requires slightly more effort to use.
When running `@profile`, the CPU data collected is saved to a global buffer which must be cleared with `Profile.clear()` each time you want to perform a new performance analysis.
Next, the call to `pprof` produces a file called `profile.pb.gz` and provides a link to open it in a locally hosted web server.
Upon opening this server in a browser, the user is presented with a call graph, which visualises how often functions call eachother.
A more traditional flamegraph view can be selected from the options menu.
Users of PProf should put `*.pb.gz` in their .gitignore file to avoid cluttering their codebase.

To integrate profile visualisations into notebook environments like Jupyter and Pluto, use [ProfileSVG.jl](https://github.com/kimikage/ProfileSVG.jl), whose outputs can be embedded into a notebook.

Note that no matter which tool you use, if your code is fast, you may need to run it multiple times in a loop.
This is because it may run quickly enough that the code is never actually sampled.
This is an issue for code faster than 1 ms on Unix systems and 10 ms on Windows, but these values can be changed (globally) by running `Profile.init(delay=0.01)`, where `delay` is measured in seconds.
Given that the sample rate is a global variable and the number of runs is a local one, it makes more sense to adjust the number of runs when required as opposed to changing the sample delay every time you run a sample.

### Allocation profiling

The Profile module also contains `Allocs`, a submodule that can be used to track down the source of allocations.
Currently, [PProf.jl](https://github.com/JuliaPerf/PProf.jl) is the only tool that can visualise this data.

```julia
using PProf
using Profile
begin
    Profile.Allocs.clear()
    do_work(xs) # Run once to precompile
    Profile.Allocs.@profile sample_rate=1 do_work(xs)
    PProf.Allocs.pprof(from_c=false)
end
```

The `sample_rate` determines the proportion of allocations that are sampled by the profiler, much like how `delay` controls how often CPU profiler probes the program to see what's going on.
A lower sample rate like 0.1 or 0.01 should be used when the code allocates "a lot", on the order of a million times, otherwise, a sample rate of 1 won't slow down data collection _too_ much.
`from_c = false` tells PProf to not display stackframes from Julia's internals that are written in C.
For more information see [this talk](https://www.youtube.com/watch?v=BFvpwC8hEWQ) at JuliaCon 2022.

A [known issue](https://github.com/JuliaLang/julia/issues/43688) with the allocation profiler is that it is not able to determine the type of every object allocated, instead `Profile.Allocs.UnknownType` is shown instead.
Inspecting the call graph can help identify which types are responsible for the allocations.

## Type stability
\tldr{Use JET.jl to automatically detect type instabilities in your code, and `@code_typed`/`@code_warntype` and Cthulhu.jl to do so manually.}

For a section of code to be considered type stable, the type inferred by the compiler must be "concrete", which means that the size of memory that needs to be allocated to store its value is known at compile time.
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

Before running any piece of code, the Julia compiler tries to determine the most specialised method it can use to ensure that the code runs as fast as possible e.g. `1+1` faster than 1 floatingpoint+ 1.
For each variable, including a function output, contained in a block of code, if all pieces of information necessary to determine its type are type inferrable, then so is the variable in question.
This means that if a variable cannot be inferred, then no variables that depend on it in any way can be either.

<!-- thanks Frames White: https://stackoverflow.com/a/58132532 -->
While type stable function calls compile down to fast `GOTO` statements, unstable function calls compile to code that reads the list of all methods for that function and find the one that matches.
This phenomenon called "dynamic dispatch" essentially prevents further optimizations via [inlining](https://en.wikipedia.org/wiki/Inline_expansion).

### Detecting instabilities
Fixing type instabilities is usually a straightforward affair once one is found, but finding the source of the instability is not always easy.
The simplest way to detect an instability is with the builtin macros `@code_typed` and `@code_warntype`:

```!interactiveutils
using InteractiveUtils  # hide
```

```>
#TODO: Find a different example, see the JET part, No errors detected
unstable_ReLU(x) = x > 0 ? x : 0;
@code_typed unstable_ReLU(-1) # Stable
@code_warntype unstable_ReLU(2.0) # Unstable!
```

The function `unstable_ReLU` is not type stable when called with a float argument.
In the output of `@code_typed`, we see in the last line that the return type is `Int64`.
However, in `@code_warntype` the return type, shown as the type of `Body`, is `Union{Float64, Int64}`, which is not concrete and is therefore flagged to the user.

The problem with this method is that, while an instability detected by the macros will be present inside the called function, it may not be the _actual_ cause of the instability, and one may need to make repeated calls to the macros to determine the underlying culprit.
This is where tools like [Cthulhu.jl](https://github.com/JuliaDebug/Cthulhu.jl) and [JET.jl](https://github.com/aviatesk/JET.jl) can help.

Cthulhu.jl exposes the `@descend` macro which can be used to interactively "step through" lines of the corresponding typed code with the arrow keys and "descend" into a particular line with `Enter`, where any instabilities can be highlighted by pressing the "w" key.
This is akin to repeatedly calling `@code_warntype` deeper and deeper into your functions, slowly succumbing to the madness...
The official [README](https://github.com/JuliaDebug/Cthulhu.jl) provides more information on the controls and options as well as a [video example](https://www.youtube.com/watch?v=pvduxLowpPY).

The best way to avoid instabilities is not to be automatically flagged when one is detected.
This is among the functionality provided by [JET.jl](https://github.com/aviatesk/JET.jl).
We previously spoke about JET in the [Sharing](../sharing/#code_quality) article in the context of [error analysis](https://aviatesk.github.io/JET.jl/stable/jetanalysis/#jetanalysis), but JET also provides [optimization analysis](https://aviatesk.github.io/JET.jl/stable/optanalysis/) aimed primarily at finding type instabilities.

While [test integrations](https://aviatesk.github.io/JET.jl/stable/optanalysis/#optanalysis-test-integration) are also provided, the interactive entry point of JET is the `@report_opt` macro.

```>JET_opt
using JET
@report_opt unstable_ReLU(1.0) #TODO: Find a different example.
```


\vscode{The Julia extension features a [static linter](https://www.julia-vscode.org/docs/stable/userguide/linter/), and runtime diagnostics with JET can be automated to run periodically on your codebase and show any problems detected.}

## Memory management

After ensuring type stability, one should try to reduce the number of heap allocations a program makes in order to spend less time in garbage collection cycles.
While this can be done with [benchmarks](#measurements) or [profiling](#profiling) as described above, this can also be done as part of your writing or CI workflow using [AllocCheck.jl](https://github.com/JuliaLang/AllocCheck.jl), a package by the official JuliaLang organisation.

By annotating a function you are writing with `@check_allocs`, if the function is run and the compiler detects that it might allocate, it will throw an error which can be inspected in a try-catch block to see exactly where this occurred.


Alternatively, to ensure that non-allocating functions never regress in future versions without you knowing, you can write a test set to check allocations by providing the function and a concrete type-signature.
```julia AllocCheck
@testset "non-allocating" begin
    @test isempty(AllocCheck.check_allocs(my_func, (Float64, Float64)))
end
```

## Precompilation

* [PrecompileTools.jl](https://github.com/JuliaLang/PrecompileTools.jl)
* [PackageCompiler.jl](https://github.com/JuliaLang/PackageCompiler.jl)
* [SnoopCompile.jl](https://github.com/timholy/SnoopCompile.jl)
* [compiling in VSCode](https://www.julia-vscode.org/docs/stable/userguide/compilesysimage/)

## Concurrency and Parallelism
\tldr{
    For multi-threaded computation, we recommend using the `@threads` macro or [Transducers.jl](https://github.com/JuliaFolds/Transducers.jl)-based extensions like [ThreadsX.jl](https://github.com/tkf/ThreadsX.jl).
    If you have multiple cores or machines, use the [Distributed](https://docs.julialang.org/en/v1/manual/distributed-computing/) standard library, [MPI.jl](https://github.com/JuliaParallel/MPI.jl) or [Elemental.jl](https://github.com/JuliaParallel/Elemental.jl).
}

### What is concurrency?
Modern computing hardware is typically capable of parallel processing, where multiple separate computations are completed at once.
The ability to manage a non-sequential order of execution, such as parallel execution, is called _concurrency_.

Parallel execution can be broken down into distributed (or multi-core) and multi-threaded execution.
Each processing core, or _process_, runs a separate instance of Julia and has access to separate memory, meaning that variables defined on one process may have different values or not be defined at all on other processes.
Each process may also be able to run threads in parallel.
These threads _do_ have access to the same variables.
In Julia, processes launched beyond the first are referred to as _workers_, as they are typically told what to do by the first process.

The advantage of shared memory is that there is very little overhead for moving a task from one thread to another, or breaking up a task such as a loop into smaller chunks to run simultanously on separate threads.
The disadvantage is that, for example, if a variable's value is overwritten by one thread after being read by a second thread, the current computation done by the second thread won't use the updated value of this variable.
This is an example of a [race condition](https://en.wikipedia.org/wiki/Race_condition), and code that guarantees that these won't occur is called [thread safe](https://en.wikipedia.org/wiki/Thread_safety).

The relative merits of shared memory mean that multi-threading is better at shorter computations, particularly where race conditions are easy to reason about such as in parallelising long loops of smaller computations.
On the other hand, moving data to and from workers takes a non-trivial amount of time, and so distributed computing is better for longer computations that don't need to share memory such as independent numerical simulations.

### Concurrency in Julia

Julia has a relatively unified model of concurrency across both threaded and distributed computing.
From the multi-threading side, there's an immutable `Task` object and a mutable `Channel` object.
A `Task` is a function call that can be executed some time in the future once it is scheduled.
The different macros and functions dealing with functions all create `Task`s, and differ in
1. When the task is executed, (immediately vs. just-in-time)
2. Whether Julia should wait for the computation to finish before moving on (blocking vs. non-blocking)
3. Which thread the task can run on (the one it's initially assigned to vs. any available thread)

From the distributed side, the equivalent of a `Task` is a `Future`.
The two objects function similarly, but you have to additionally reason about moving data/functions over to the Julia process that's going to do the work.

A `Channel`, and its distributed equivalent `RemoteChannel`, is a first-in-first-out queue to `put!` and `take!` results from concurrent processes.
This is useful for constructing concurrent pipelines with multiple sources and/or processors of tasks.

#### Multi-threading

The number of threads that Julia runs with can be set through one of the following equivalent command line flags, providing an integer or `auto`:
```bash threads-flag
julia --threads 4
julia -t auto
```

Once Julia is running, you can check if this was successful by running `Threads.nthreads()`.

\vscode{
    The default number of threads can be edited by adding `"julia.NumThreads": 4,` to your settings.json. This will be applied to the integrated terminal.
}

\advanced{
    Linear algebra code calls the low-level libraries [BLAS](https://en.wikipedia.org/wiki/Basic_Linear_Algebra_Subprograms) and [LAPACK](https://en.wikipedia.org/wiki/LAPACK).
    These libraries manage their own pool of threads, so single-threaded Julia processes can still make use of multiple threads, and multi-threaded Julia processes that call these libraries may run into performance issues due to the limited number of threads available in a single core.
    In this case, once LinearAlgebra is loaded, BLAS can be set to use only one thread by calling `BLAS.set_num_threads(1)`.
    For more information see the [Julia manual](https://docs.julialang.org/en/v1/manual/performance-tips/#man-multithreading-linear-algebra).
}

The simplest way to use multi-threading is to parallelise a for loop with `Threads.@threads`. 
```julia @threads-forloop
results = zeros(Int, 4)
Threads.@threads for i in 1:4
    results[i] = i^2
end
```

Alternatively, `@spawn` can be used _inside_ an iteration procedure to run the expression following on any available thread.
In order to get Julia to "block" i.e. to wait for these tasks to be finished before proceeding with execution beyond the loop, it must be annotated with `@sync`.
```julia @spawn-forloop
results = zeros(Int, 4)
@sync for i in 1:4
    Threads.@spawn results[i] = i^2
end
```

`@spawn` can also be used to parallelise a `map`, but rather than returning the result of the called function, the macro instead returns a `Task` object, the results of which must be `fetch`ed.
Similarly to `@sync`, `fetch` asks the `Task` for the results of the function call and blocks Julia from proceeding until this is available.
```> @spawn-map
tasks = map(i -> Threads.@spawn(i^2), 1:4)
results = fetch.(tasks)
```

The final macro you may come across (particularly in older code) is `@async`, which functions similarly to `@spawn`: the two differ only in how tasks are scheduled.
When `@async` creates a `Task`, it also declares that they can only be executed on the first thread they are assigned to.
This means that if one thread finishes all of its tasks quickly, it has to idle until all other threads are also finished.
On the contrary, `@spawn`'s tasks are scheduled _dynamically_, and tasks can even switch thread mid execution if the scheduler deems it faster.
Dynamic scheduling is the default for `@threads` since Julia 1.8, and while `@async` and `@threads :static` are still options, their use is [strongly discouraged](https://docs.julialang.org/en/v1/base/parallel/#Base.@async) unless the static scheduling functionality is required.

\advanced{
    For maximum performance, `@threads` should be used over `@spawn`/`@sync` because, as stated in the [documentation](https://docs.julialang.org/en/v1/base/multi-threading/#Base.Threads.@threads) of `@threads`, "each task processes contiguous regions of the iteration space".
}

##### Multi-threading ecosystem

Julia's robust task scheduler allows Threads to be a very flexible library, but this robustness also leads to longer latency before tasks can be run when spinning up new threads.
[ThreadingUtilities.jl](https://github.com/JuliaSIMD/ThreadingUtilities.jl/) provides a low-level interface to starting fast, lightweight threads exposed to users through packages such as:
- [Polyester.jl](https://github.com/JuliaSIMD/Polyester.jl) for a Threads-like interface with `@batch` with a reduction argument like `@distributed` (see [below](#distributed_computing)),
- [LoopVectorization.jl](https://github.com/JuliaSIMD/LoopVectorization.jl) for _maximal performance_ with loops via `@turbo` and `@tturbo` (see the [SIMD](#simd_and_gpu_programming) section for details), 
- [Octavian.jl](https://github.com/JuliaLinearAlgebra/Octavian.jl) for multi-threaded linear algebra operations built ontop of LoopVectorization.jl.

The [ThreadingUtilities.jl ecosystem](https://github.com/JuliaSIMD) will be deprecated in Julia 1.11 due to a lack of maintainers.

[Transducer.jl](https://github.com/JuliaFolds2/Transducers.jl) is a package which allows for composition of higher-order functions like `map` and `reduce` in a memory-efficient way.
The provided functions e.g. `Map` are automatically parallelised, as are their compositions, leading to simple to write, yet very efficient parallel code.
The package also unifies the API of working with multi-threaded and distributed code.

A number of packages use Transducers under the hood to make writing parallel programs easy.
This includes the parallelised Base functions of [Folds.jl](https://github.com/JuliaFolds2/Folds.jl) and [ThreadsX.jl](https://github.com/tkf/ThreadsX.jl).

Maintained by the same organisation, [OhMyThreads.jl](https://github.com/JuliaFolds2/OhMyThreads.jl) is an easy-to-use alternative to Base Threads.
Like Folds and ThreadsX, it provides multi-threaded (notably, not distributed) Base functions as well as its own macro-based API.
For those already familiar with Base Threads, a [translation guide](https://juliafolds2.github.io/OhMyThreads.jl/stable/translation/) can help get started with OhMyThreads.

<!-- Should we talk about nchunks to speed up potentially unbalanced workloads? -->

<!-- \advanced{
    Sometimes, multi-threaded applications themselves spawn threads. In this case, Julia's task scheduling is depth-first, which is typically [better for high-performance computing](https://www.youtube.com/watch?v=YdiZa0Y3F3c), and was the culmination of an [Intel research project](https://www.intel.com/content/www/us/en/developer/articles/technical/new-threading-capabilities-in-julia-v1-3.html) implemented in Julia.
} -->

<!-- \advanced{
    Those familiar with concurrent programming in other languages may note that Julia's asynchronous programming is implemented as [green threading](https://en.wikipedia.org/wiki/Green_thread) like in [Go](https://go.dev/tour/concurrency/1).
    This is is semantically different to async/await found in [Python](https://docs.python.org/3/library/asyncio.html), [Javascript](https://developer.mozilla.org/en-US/docs/Learn/JavaScript/Asynchronous/Promises), and [Rust](https://doc.rust-lang.org/std/keyword.async.html).
The upshot of this is that writing asynchronous programs is semantically similar to writing multi-threaded code.
} -->

<!-- For another great overview of this topic, see this [post](https://lwn.net/Articles/875367/) on LWN.net. -->

#### Distributed computing

<!-- Julia's model of distributed computing explained [in the docs](https://docs.julialang.org/en/v1/manual/distributed-computing/) is similar to its model of multi-threading. -->
As explained earlier, Julia's [model of distributed computing](https://docs.julialang.org/en/v1/manual/distributed-computing/) is similar to its model of multi-threading.
The complications and caveats to this that we highlight come from the fact that data is not shared between worker processes.

Additional worker processes can be added with `addprocs`, the number of which can be queried with `nworkers`.
These can run on local threads or remote machines (via [SSH](https://en.wikipedia.org/wiki/Secure_Shell)).

In the Base Distributed library, there exist _syntactic_ equivalents for `@threads` and `@spawn`: `@distributed` and `@spawnat`, respectively.
Hence, we can use `@distributed` to parallelise a for loop, but we have to deal with sharing and recombining the `results` array.
We can delegate this responsibility to the SharedArrays library, but in order for all workers to know about this library, we have to load it `@everywhere`.

``` @distributed-forloop
using Distributed

# Add additional workers then load code on the workers
addprocs(3) 
@everywhere using SharedArrays
@everywhere f(x) = 3x^2

results = SharedArray{Int}(4)
@sync @distributed for i in 1:4
    results[i] = f(i)
end
```

While syntactically similar to `@threads`, `@distributed` does not block execution, so we must `@sync` so Julia waits for all processes to finish computation before moving on.

One feature `@distributed` has over `@threads` is the possibility to specify a reduction function (an [associative binary operator](https://en.wikipedia.org/wiki/Associative_property)) which combines the results of each worker.
In this case `@sync` is implied, as the reduction cannot happen unless all of the workers have finished.

```!Distributed
using Distributed  # hide
```

```julia @distributed-sum
@distributed (+) for i in 1:4
    i^2
end
```

Alternatively, `@spawnat` can be used like `@spawn`, but the user must specify which process should execute the expression, or mark it as `:any`.
```julia @spawn-forloop
for i in 1:4
    @spawnat :any results[i] = i^2
end
```

Finally (for this blog), the convenience macro `pmap` can be used to easily parallelise a map, both in a distributed and multi-threaded way by specifying how large:
```julia
results = pmap(f, 1:100; distributed=true, batch_size=25, on_error=ex->0)
```

#### Distributed computing ecosystem

[MPI.jl](https://github.com/JuliaParallel/MPI.jl) implements the [Message Passing Interface standard](https://en.wikipedia.org/wiki/Message_Passing_Interface), which is heavily used in high-performance computing beyond Julia.
The C library that MPI.jl wraps is _highly_ optimized, so Julia code that needs to be scaled up to a large number of cores, such as an HPC cluster, will typically run faster with MPI than Distributed.

[Elemental.jl](https://github.com/JuliaParallel/Elemental.jl) is a package for distributed dense and sparse linear algebra which wraps the [Elemental](https://github.com/LLNL/Elemental) library written in C++, itself using MPI under the hood.

## SIMD and GPU programming

### SIMD programming
__Single instruction, multiple data__, abbreviated as __SIMD__, is a form of data-level parallelism.
Distinct from the task-level parallelism of the previous section, data parallelism has no need for concurrent scheduling because the processing units can _only_ perform the same instruction at the same time, differing only in their inputs.

On CPUs, the SIMD paradigm is implemented by building wide floating-point registers into the CPU that can store small, fixed-size arrays of floats.
Accompanying this, the CPU vendor extends the [x86 architecture](https://en.wikipedia.org/wiki/X86) to perform arithmetic on the entire array at in a single operation.
This is called _(instruction-level) vectorization_.

_Function-level vectorization_ is a related concept in which code that could have been written as a loop is written using Julia's broadcasting syntax `f.(x)`/`x .+ y`.
While such vectorization is all but required in languages like R,  MATLAB, and Python for performant array-based code, Julia's loops are very fast as is, and broadcasting is typically just syntactic sugar.
However, this syntax has the added benefit of making it easy to use memory efficiently.
Dot-broadcasting `@.`, also known as chained broadcasting or [syntactic loop fusion](https://julialang.org/blog/2017/01/moredots/), allows Julia to avoid allocating memory for intermediate operations, providing a large speedup and performance similar to explicitly written loops.

#### Instruction-level vectorization
Julia uses [LLVM](https://en.wikipedia.org/wiki/LLVM) under the hood, which can automatically vectorize various forms of repeated numerical operations, which most frequently appears as loops over one-dimensional indices and repeated lines of code with similar instructions.
There are a number of requirements that need to be met to apply SIMD optimizations:
1. Reordering operations, or executing them simultaneously, must not change the result of the computation,
2. There must be no control flow/branches in the core computation,
3. All array accesses must have some linear pattern to them between loop iterations or lines of code.

While this may seem straightforward, particularly for linear algebra-heavy code, there are a number of important caveats which can prevent code from being vectorized.
1. To reorder operations and guarantee the same result, all operations must be [associative](https://en.wikipedia.org/wiki/Associative_property) and finite-precision float operations are [_not_](https://docs.oracle.com/cd/E19957-01/806-3568/ncg_goldberg.html). The `@simd` macro allows Julia to rearrange your operations, resulting in a different, equally valid answer.
2. Indexing into an array requires a bounds check to see if the index is actually in the bounds of the array, you can use `@inbounds` to eliminate these checks and enable vectorization. On the contrary, control flow where both branches can be safely evaluated are permitted, thus `ifelse` can also encourage vectorization if your code fits this criteria.
3. The access pattern of a loop is typically referred to as a _stride_. If this pattern doesn't have a "nice" order, say `a + bk` for integer constants `a`, `b`, and loop index `k`, such as views generated by permutations or filter masking, then the code cannot be automatically vectorized and [explicit vectorization tools](#explicit_vectorization) must be used.

To see if instructions are being vectorized, look for `<n x type>` instructions in the output of `@code_llvm`:

```julia SIMD-llvm
# From "SIMD and SIMD-intrinsics in Julia" by Kristoffer Carlsson
function axpy!(c::Array, a::Array, b::Array)
    @assert length(a) == length(b) == length(c)
    @inbounds for i in 1:length(a)
        c[i] = a[i] * b[i]
    end
end
code_llvm(axpy!, Tuple{Vector{Float64}, Vector{Float64}, Vector{Float64}})
```
<!-- 
```llvm
# TODO: output looks something like this

```
-->
#### Explicit instruction-level vectorization
[SIMD.jl](https://github.com/eschnett/SIMD.jl) allows users to force the use of SIMD instructions and bypass the check for whether this is possible.
One particular use-case for this is for vectorising non-contiguous memory reads and writes through `vgather` and `vscatter` (and their indexing syntaxes) respectively:
```julia
# From the SIMD.jl README
arr = zeros(10)
v = Vec((1.0, 2.0, 3.0, 4.0)) # create SIMD vector
idx = Vec((1, 3, 4, 7))
v = arr[idx]                  # vgather
arr[idx] = v                  # vscatter
```

\advanced{
    VecElement is a built-in type intended for use with `llvm_call` to force vectorization.
}

#### Tensor operations
A few packages implement Einstein notation for tensor operations, which are all typically very performant.
- [Tullio.jl](https://github.com/mcabbott/Tullio.jl)'s eponymous macro `@tullio` allows for arbitrary element-wise operations and automatically uses LoopVectorization.jl and multithreading if available.
- [OMEinsum.jl](https://github.com/under-Peter/OMEinsum.jl) offers a NumPy `einsum`-like interface, re-use of array indices in the same expression, and support for generic element types.
- [TensorCast.jl](https://github.com/mcabbott/TensorCast.jl) splits broadcasting and reductions into separate macros `@cast` and `@reduce`.
- [TensorOperations.jl](https://github.com/Jutho/TensorOperations.jl) also exists.

### GPU programming

While CPU SIMD instructions can provide a large speed-up, they are limited to the width of the vector registers.
Vectors of four 32-bit floats can be added together in a single instruction, whereas if they were one element longer it would take two (as well as additional load instructions).


* [KernelAbstractions.jl](https://github.com/JuliaGPU/KernelAbstractions.jl)

## Efficient types
\tldr{Be aware that [StaticArrays.jl](https://github.com/JuliaArrays/StaticArrays.jl) exist and learn how they work}

Using an efficient data structure is a tried and true way of improving the performance.
While users can write their own efficient implementations through officially documented [interfaces](https://docs.julialang.org/en/v1/manual/interfaces/), a number of packages containing common use cases are more tightly integrated into the Julia ecosystem.


### Static Arrays

Using [StaticArrays.jl](https://github.com/JuliaArrays/StaticArrays.jl), you can construct arrays that contain not only their type information, but also their size.
With `MArray`, `MMatrix`, and `MVector`, data is mutable as in normal arrays.
However, the corresponding `SArray`, `SMatrix` and `SVector` types are immutable, so the object does not need to be garbage collected as it can be stack-allocated.
Additionally, through multiple dispatch, statically sized arrays can have specialised, efficient methods for certain algorithms such as [QR-factorisation](https://juliaarrays.github.io/StaticArrays.jl/stable/pages/api/#LinearAlgebra.qr-Tuple{StaticArray{Tuple{N,%20M},%20T,%202}%20where%20{N,%20M,%20T}}).

`SArray`s, as stack-allocated objects like tuples, cannot be mutated, but should instead be replaced entirely.
Doing so comes at almost no extra cost compared to directly editing the data of a mutable object.
For a more familiar in-place update syntax for immutable data structures like `SArrays`s, you can use [Accessors.jl](https://github.com/JuliaObjects/Accessors.jl):

```julia accessors-example
using StaticArrays, Accessors

sx = SA[1, 2, 3] # SA constructs an SArray
@set sx[1] = 3 # Returns a copy, does not update the variable
@reset sx[1] = 4 # Replaces the original
```

\advanced{
    You can make your own array types with nice interfaces easily by inheriting from `FieldArray`/`FieldMatrix`/`FieldVector`.
```>
struct CustomVector <: FieldVector{2, Float64}
    a::Float64
    b::Float64
end
result = CustomVector(2.0, 3.0) ./ CustomVector(5.0, 6.0)
result.a
```
}

### Other data structures

All but the most obscure data structures can be found in the packages from the [JuliaCollections](https://github.com/JuliaCollections) organisation, along with useful packages for [iteration](https://github.com/JuliaCollections/IterTools.jl) and [memoization](https://github.com/JuliaCollections/Memoize.jl).

The largest package amanged by the organization is [DataStructures.jl](https://github.com/JuliaCollections/DataStructures.jl) which, to name a few, contains the [`Stack` and `Queue`](https://juliacollections.github.io/DataStructures.jl/stable/stack_and_queue/) structures, the rarer [`Trie`](https://juliacollections.github.io/DataStructures.jl/stable/trie/), [`RedBlackTree`](https://juliacollections.github.io/DataStructures.jl/stable/red_black_tree/), and [`DiBitVector`](https://juliacollections.github.io/DataStructures.jl/stable/dibit_vector/), as well as [various](https://juliacollections.github.io/DataStructures.jl/stable/robin_dict/) [hashmap](https://juliacollections.github.io/DataStructures.jl/stable/swiss_dict/) [variations](https://juliacollections.github.io/DataStructures.jl/stable/sorted_containers/#).

As an alternative to the builtin `Base.Dict`, [`Dictionaries.jl`](https://github.com/andyferris/Dictionaries.jl) implements a number of different types of hashmap, each with their own strengths and weaknesses.
For example, as stated in the README, the flagship `Dictionary` preserves the order of inserted elements and iterates faster partly due to this ordering.
Its drawback is that insertion and deletion are slower than `Base.Dict`.