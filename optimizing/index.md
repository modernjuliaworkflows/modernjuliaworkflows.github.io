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

using BenchmarkTools
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

Code can be made to run faster through parallel execution with multithreading or distributed computing.
Many common operations such as maps and reductions can be trivially parallelised through either method by using their respective Julia packages.
Multithreading is available on almost all modern hardware, whereas distributed computing is most useful to users of high-performance computing clusters.

### Multithreading
To enable multithreading, the number of threads that Julia runs with can be set through one of the following equivalent command line flags, providing an integer or `auto`:
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

The builtin `Threads` package contains a simple way to use multi-threading is to parallelise a for loop with `Threads.@threads`. 
```julia @threads-forloop
results = zeros(Int, 4)
Threads.@threads for i in 1:4
    results[i] = i^2
end
```

The macros `@spawn` and `@async` function similarly, but require more manual management of the results, which can result in bugs and performance footguns.
For this reason `@threads` is recommended for those who do not wish to use third-party packages.

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

#### Distributed computing

<!-- Julia's model of distributed computing explained [in the docs](https://docs.julialang.org/en/v1/manual/distributed-computing/) is similar to its model of multi-threading. -->
Julia's [model of distributed computing](https://docs.julialang.org/en/v1/manual/distributed-computing/) is similar to its model of multi-threading.
The complications and caveats to this that we highlight come from the fact that data is not shared between worker processes.

Once Julia is started, additional "worker" processes can be added with `addprocs`, the number of which can be queried with `nworkers`.
These can run on local threads or remote machines (via [SSH](https://en.wikipedia.org/wiki/Secure_Shell)).

In the base `Distributed` library, `@distributed` is a _syntactic_ equivalent for `Threads.@threads`.
Hence, we can use `@distributed` to parallelise a for loop as before, but we have to additionally deal with sharing and recombining the `results` array.
We can delegate this responsibility to the base `SharedArrays` library, but in order for all workers to know about this library, we have to load it `@everywhere`.

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

Note that `@distributed` does not make the main process wait for the other workers to finish computation, so we must `@sync` so Julia blocks execution.

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

Finally (for this blog), the convenience macro `pmap` can be used to easily parallelise a map, both in a distributed and multi-threaded way:
```julia
results = pmap(f, 1:100; distributed=true, batch_size=25, on_error=ex->0)
```

#### Distributed computing ecosystem

[MPI.jl](https://github.com/JuliaParallel/MPI.jl) implements the [Message Passing Interface standard](https://en.wikipedia.org/wiki/Message_Passing_Interface), which is heavily used in high-performance computing beyond Julia.
The C library that MPI.jl wraps is _highly_ optimized, so Julia code that needs to be scaled up to a large number of cores, such as an HPC cluster, will typically run faster with MPI than Distributed.

[Elemental.jl](https://github.com/JuliaParallel/Elemental.jl) is a package for distributed dense and sparse linear algebra which wraps the [Elemental](https://github.com/LLNL/Elemental) library written in C++, itself using MPI under the hood.


## SIMD and GPU programming

### SIMD instructions
In the __Single instruction, multiple data__ paradigm, abbreviated as __SIMD__, processing units perform the same instruction at the same time, differing only in their inputs.
This means that the previous section's complicated task scheduling macros are not required, but the type of operations that can be parallelised in this way are more limited.

Through [LLVM](https://en.wikipedia.org/wiki/LLVM), Julia can automatically vectorize repeated numerical operations (such as those found in loops) provided a few conditions are met:
1. Reordering operations, or executing them simultaneously, must not change the result of the computation,
2. There must be no control flow/branches in the core computation,
3. All array accesses must have some linear pattern to them between loop iterations or lines of code.

While this may seem straightforward, particularly for linear algebra-heavy code, there are a number of important caveats which can prevent code from being vectorized.
1. To reorder operations and guarantee the same result, all operations must be [associative](https://en.wikipedia.org/wiki/Associative_property) and finite-precision float operations are [_not_](https://docs.oracle.com/cd/E19957-01/806-3568/ncg_goldberg.html). The `@simd` macro allows Julia to rearrange your operations, resulting in a different, equally valid answer.
2. Indexing into an array requires a bounds check to see if the index is actually in the bounds of the array, you can use `@inbounds` to eliminate these checks and enable vectorization. On the contrary, control flow where both branches can be safely evaluated are permitted, thus `ifelse` can also encourage vectorization if your code fits this criteria.
3. The access pattern of a loop is typically referred to as a _stride_. If this pattern doesn't have a "nice" order, say `a + bk` for integer constants `a`, `b`, and loop index `k`, such as views generated by permutations or filter masking, then the code cannot be automatically vectorized and [explicit vectorization tools](#explicit_vectorization) must be used.

You can detect whether the optimizations have occurred by inspecting the output of `@code_llvm` or `@code_native` and looking for vectorised registers, types, instructions.
While the exact things you're looking for will vary between code and CPU instruction set, an example of what to look for can be seen in this [blog post](https://kristofferc.github.io/post/intrinsics/) by Kristoffer Carlsson.

#### Explicit instruction-level vectorization
[SIMD.jl](https://github.com/eschnett/SIMD.jl) allows users to force the use of SIMD instructions and bypass the check for whether this is possible.
One particular use-case for this is for vectorising non-contiguous memory reads and writes (see condition 3 above) through `vgather` and `vscatter` respectively:
```julia
# From the SIMD.jl README
using SIMD
arr = zeros(10)
v = Vec((1.0, 2.0, 3.0, 4.0)) # create SIMD vector
idx = Vec((1, 3, 4, 7))
v = arr[idx]                  # vgather (invoked by indexing syntax)
arr[idx] = v                  # vscatter
```

### GPU programming

GPUs are specialised in executing instructions in parallel over a large number of threads.
While they were originally designed for accelerating graphics rendering, more recently they have been used to train and evaluate neural network models.

Julia's GPU ecosystem is managed by the [JuliaGPU](https://juliagpu.org/) organisation, which provides not only individual packages for directly working with each GPU vendor's instruction set, but also a way to write vendor-agnostic kernels through [KernelAbstractions.jl](https://github.com/JuliaGPU/KernelAbstractions.jl).

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