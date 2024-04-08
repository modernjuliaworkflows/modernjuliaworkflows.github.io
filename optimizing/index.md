+++
title = "Optimizing your code"
+++

\activate{}

# Optimizing your code

\toc

## Principles

All [tips](https://docs.julialang.org/en/v1/manual/performance-tips/) to writing performant Julia code can be derived from two fundamental ideas:
1. Ensure that the compiler can derive the type of every variable so optimizations be performed.
2. Avoid unnecessary heap allocations which slow the code down.

The compiler's job is to optimize and translate Julia code it into runnable [machine code](https://en.wikipedia.org/wiki/Machine_code).
If some information about a variable's type isn't available to the compiler, for example because the [return type of a function is value-dependent](https://docs.julialang.org/en/v1/manual/performance-tips/#Write-%22type-stable%22-functions), then it cannot safely perform its most powerful optimizations as it cannot satisfy assumptions required for the optimizations to be performed. For more information see [below](#type_stability).

A "heap" allocation occurs whenever a variable is allocated whose type doesn't contain enough information to know exactly how much space is required to store all of its data.
An example of this is `Vector{Int}`, which doesn't contain information about how many elements the vector has.
In order to manage the deallocation of objects after their usage, Julia has a [mark-and-sweep](https://en.wikipedia.org/wiki/Tracing_garbage_collection#Copying_vs._mark-and-sweep_vs._mark-and-don't-sweep) [garbage collector](https://docs.julialang.org/en/v1/devdocs/gc/), which runs periodically during code execution to free up space so that other objects can be allocated.
Execution of code is stopped while the garbage collector runs, so minimising its usage is important.

In the example below, we break both fundamental principles.

```>break-rules-example
x = rand(100)
function bad_function(y)
    a = x + y
    b = x - y
    c = a ./ b
end;
y = rand(100)
bad_function(y) # run once to compile the function
using BenchmarkTools
@btime bad_function(y)
```

While `y` is correctly passed as an argument to `bad_function`, `x` isn't, and because it is an [untyped global variable](https://docs.julialang.org/en/v1/manual/performance-tips/#Avoid-untyped-global-variables), its type must be inferred each time the function is run, which results in an allocation.
This could be solved by redefining `bad_function` to accept both `x` and `y` as arguments.
```>remove-untyped-global
function better_function(x, y)
    a = x + y
    b = x - y
    c = a ./ b
    return c # technically superfluous return, but highly recommended for clarity
end;
@btime better_function(x, y)
```

Moreover, even if the user only cares about the value of `c` the variables `a` and `b` are still heap allocated.
Notably, this _cannot_ simply be improved by writing the function as

```>no_better
function no_better_function(x, y)
    c = (x + y) ./ (x - y)
    return c
end;
```

because Julia allocates intermediate values in the same line.
The way to avoid intermediate allocations is to reuse memory as much as possible.
Typically, the simplest way to do this is to "fuse" operations through broadcasting with `@.`

```>fuse-operations
function best_function(x, y)
    c = @. (x + y) ./ (x - y)
    return c
end;
```
Finally, a common design pattern in Julia packages to achieve convenience and offer the best performance to end users is to write a non-allocating, in-place version of a function which performs all of the computation, and an allocating version which simply preallocates memory, and calls into the in-place function:

```>timings
function best_function!(c, x, y)
     @. c = (x + y) ./ (x - y)
    return nothing
end;
function best_function(x, y)
    c = zeros(size(x))
    best_function!(c, x, y)
    return c
end
@btime best_function(x, y)
c = zeros(100)
@btime best_function!(c, x, y)
```

<!-- Let's look at an illustrative example that breaks both of these rules.
To break the first, we define a global variable which we later use many times [without passing it to a function](https://docs.julialang.org/en/v1/manual/performance-tips/#Avoid-untyped-global-variables) or annotating its type [at the point of usage](https://docs.julialang.org/en/v1/manual/performance-tips/#Annotate-values-taken-from-untyped-locations).
Hence its type must be determined at runtime every time it is used. -->

<!-- For the second, we perform vector operations without fusing them with `@.` or performing them inplace with `@views` such that new memory is allocated for every intermediate result.

```>break-rules-example
X = rand(500, 500)
function do_work(y)
    ans = zeros(500, 10)
    for i in 1:10
        ans[:, i] = X*X #.+ transpose(y)*y .+ X*y
    end
    return ans
end
do_work(rand(500))
```

Secondly, Julia has a [garbage collector](https://en.wikipedia.org/wiki/Garbage_collection_(computer_science)) whose job is to determine which variables no longer need to be stored in memory and free this memory so it can be reused.
Variables whose type determines how much memory they require to be stored can be allocated and freed almost for free, but variables without this property must be managed by the garbage collector and stored on the ["heap"](https://en.wikipedia.org/wiki/Memory_management).
In our example, our `AwfulNumber` will allocate 100, vectors of length 100,000 every time the user _dares_ to multiply it with another number.

Combining these two fundamental ideas together, and then entirely ignoring them, we define our own number type whose multiplication method allocates lots of memory many times, and then refuse to tell the compiler whether our variable has our awful type or not:

```>awful-number-example
struct AwfulNumber <: Number
    n::Int
end

import Base.*

function *(x::Number, y::AwfulNumber)
    for _ in 1:100
        _ = rand(100_000)
    end
    return x * y.n
end

# num::Union{Int, AwfulNumber} = AwfulNumber(2)
num = AwfulNumber(2)
@time 2*AwfulNumber(2)
@time 2*num
@time 2*3
```

In the following example, we can see that untyped global variables cause slowdowns precisely because their type can't be inferred.
To accurately measure runtime we use [`@btime`](#measurements).

```>instability-example
function f(x, y)
    return x^2 + 2*x*y + y^2
end

x_untyped, y_untyped = 5, 2
x_typed::Int, y_typed::Int = 5, 2

@time f(x_untyped, y_untyped)
@time f(x_typed, y_typed)
```

If a global variable is left untyped, then the user could reassign it to a different type at any time, and so the compiler can never optimize code using its current type.
This is just one way that type instability can appear in Julia code, and this topic, as well as tools to find and fix it, is further explored in a [later section](#type-stability).

A heap allocation occurs when an object is to be allocated, but how much space to allocate cannot be inferred from its type.
Its counterpart is the [stack allocation](https://en.wikipedia.org/wiki/Stack-based_memory_allocation), which will only be performed if the object being allocated has a known size *and* its data cannot be modified after allocation i.e. the data is [immutable](https://en.wikipedia.org/wiki/Immutable_object).
The benefit of these stringent rules is that stack allocations and deallocations are so fast that they are considered negligible by Julia's benchmarking tools (detailed below) and are not included in the total count of allocations.
On the other hand, objects on the heap cannot be so heavily optimized by the compiler as the data and its size may change.
In order to manage the deallocation of heap objects after their usage, Julia has a [mark-and-sweep](https://en.wikipedia.org/wiki/Tracing_garbage_collection#Copying_vs._mark-and-sweep_vs._mark-and-don't-sweep) [garbage collector](https://docs.julialang.org/en/v1/devdocs/gc/), which runs periodically during code execution to free up space so that other objects can be allocated.
The necessity of the garbage collector combined with the lack of optimizations means that heap allocations, while incredibly useful and oftentimes necessary, should be avoided if possible.

Paraphrasing the Julia manual's [performance tips](https://docs.julialang.org/en/v1/manual/performance-tips/) section: the most common causes of the "unnecessary" heap allocations are type-instability and unintended temporary arrays.
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
More important than this specific fix is more generally that the more precise you are about what exactly the code should do, the better performance you are able to achieve.

The type instability is a result of the final line `result > 0 ? result : 0`.
What type does the function return?
Sometimes it returns the integer `0`, whereas other times it returns `result`, which is, in most cases, a `Float64`.
This dependence on run-time value as opposed to compile-time type results in the instability, causing an additional heap allocation which slows the function down further.
We can fix this instability simply by replacing the final `0` with `zero(result)`, which returns the zero element of whatever type `result` happens to be. -->

Any specific performance tip, either those found in the [manual](https://docs.julialang.org/en/v1/manual/performance-tips/) or elsewhere, will ultimately come down to these two fundamental ideas.
For example, it's recommended to [__Avoid untyped global variables__](https://docs.julialang.org/en/v1/manual/performance-tips/#Avoid-untyped-global-variables).
Why? Because the type of a global variable could change, so it causes type instability wherever it is used without being passed to a function as an argument.
Why might you want to [preallocate outputs](https://docs.julialang.org/en/v1/manual/performance-tips/#Pre-allocating-outputs) and [fuse vectorized opterations](https://docs.julialang.org/en/v1/manual/performance-tips/#More-dots:-Fuse-vectorized-operations)? To minimise heap allocations.

## Measurements

\tldr{Use BenchmarkTools.jl's `@benchmark` with a setup phase to get the best overview of performance or `@btime` as a drop in for `@time`. Use Chairmarks.jl as a faster alternative.}

The simplest way to measure how fast a piece of code runs is to use the `@time` macro, which returns the result of the code and prints time, allocation, and compilation information.
Because code needs to be compiled before it can be run, you should first run a function without timing it so it can be compiled, and _then_ time it:

```>time-example
sum_abs(vec) = sum(abs, vec)
v = rand(100)
@time sum(abs,v)
@time sum(abs,v)
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

<!-- ```>$-randomness-example
@btime sum_abs($(rand(10)))
``` -->

However, doing so will mean that any randomness will be the same for every run!
Furthermore, constructing and interpolating multiple variables can get messy.
As such, the best way to run a benchmark is to construct variables in a `setup` phase.
Note that variables constructed this way should not be interpolated in as this indicates that BenchmarkTools should search for a global variable with that name.

<!-- ```>setup-example
my_matmul(A, b) = A * b;
@btime my_matmul(A, b) setup=(
    # use semi-colons inside a setup block to start new lines
    A = rand(1000, 1000);
    b = rand(1000)
)
``` -->

A setup phase means that you get a full overview of a function's performance as not only are you running the function many times, each run also has a different input.

For the best visualisation of performance, the `@benchmark` macro is also provided which shows performance histograms:
<!-- ```>benchmark-example
@benchmark my_matmul(A, b) setup=(
    A = rand(1000, 1000);
    b = rand(1000)
)
``` -->

Finally, it's worth noting that certain computations may be optimized away by the compiler before the benchmark takes place, resulting in suspicuously fast performance, however the [details of this](https://juliaci.github.io/BenchmarkTools.jl/stable/manual/#Understanding-compiler-optimizations) are beyond the scope of this post and most users should not worry at all about this.

### Chairmarks.jl
This package offers an alternative to BenchmarkTools.jl, promising _significantly_ faster benchmarking at the cost of

### Other tools

The setup above is great for individual lines of code, but get insight into which parts of a larger program are bottlenecks it is recommended to use a [profiler](#profiling) or a lightweight tool like [TimerOutputs.jl](https://github.com/KristofferC/TimerOutputs.jl).
TimerOutputs allows you to label and time different sections of your code and summarise their performance by label.

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

<!-- TODO: Elaborate -->
To run this suite manually use [PkgBenchmark.jl](https://github.com/JuliaCI/PkgBenchmark.jl)

However, catching regressions is much easier when it is automated which is what tools like [AirSpeedVelocity.jl](https://github.com/MilesCranmer/AirspeedVelocity.jl) and [PkgJogger.jl](https://github.com/awadell1/PkgJogger.jl) aim to help with.

## Profiling

* [built-in profiler](https://docs.julialang.org/en/v1/manual/profile/) and [allocation profiler](https://docs.julialang.org/en/v1/stdlib/Profile/#Memory-profiling)
* [ProfileView.jl](https://github.com/timholy/ProfileView.jl) / [ProfileSVG.jl](https://github.com/kimikage/ProfileSVG.jl)
* [PProf.jl](https://github.com/JuliaPerf/PProf.jl)
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

* [Cthulhu.jl](https://github.com/JuliaDebug/Cthulhu.jl)
* [JET.jl](https://github.com/aviatesk/JET.jl)
* [linting in VSCode](https://www.julia-vscode.org/docs/stable/userguide/linter/)

## Memory management

After ensuring type stability, one should try to reduce the number of heap allocations a program makes in order to spend less time in garbage collection cycles.
While this can be done using the timing macros above (`@time`, `@btime`, `@b`), this can also be done as part of your writing or CI workflow using [AllocCheck.jl](https://github.com/JuliaLang/AllocCheck.jl), a package by the official JuliaLang organisation.

By annotating a function you are writing with `@check_allocs`, if the function is run and the compiler detects that it might allocate, it will throw an error which can be inspected in a try-catch block to see exactly where this occurred.

<!-- This currently segfaults Julia, see https://github.com/JuliaLang/AllocCheck.jl/issues/67 -->
<!-- ```>alloc-writing-workflow
using AllocCheck
@check_allocs my_add(x, y) = x .+ y
my_add(SA[1, 2, 3], SA[4, 5, 6])
try
    my_add([1, 2, 3], [4, 5, 6])
catch e
    e.errors[1]
end
``` -->

Alternatively, to ensure that non-allocating functions never regress in future versions without you knowing, you can write a test set to check allocations by providing the function and a concrete type-signature.
```julia
@testset "non-allocating" begin
    @test isempty(AllocCheck.check_allocs(my_func, (Float64, Float64)))
end
```

A common pattern in Julia code is `push!`ing to a vector, which can be made more efficient by using a `collector` from [BangBang.jl](https://github.com/JuliaFolds/BangBang.jl), which aims to allow users to interact with immutable and mutable data structures using the same syntax.

```julia
# Inefficient
result = Int64[]
for i in 1:10
    push!(result, i)
end
result

# Weird flex but ok
result = SVector{0, Int64}
for i in 1:10
    push!!(result, i)
end
result

# Efficient
result = collector()
for i in 1:10
    push!!(result, i)
end
finish!(result)
```

## Precompilation

* [PrecompileTools.jl](https://github.com/JuliaLang/PrecompileTools.jl)
* [PackageCompiler.jl](https://github.com/JuliaLang/PackageCompiler.jl)
* [SnoopCompile.jl](https://github.com/timholy/SnoopCompile.jl)
* [compiling in VSCode](https://www.julia-vscode.org/docs/stable/userguide/compilesysimage/)

## Parallelism

Julia provides [built-in support](https://docs.julialang.org/en/v1/manual/parallel-computing/) for asynchronous, distributed, and multi-threaded computing.
Notably, Julia's task scheduling is depth-first, which is typically [better for high-performance computing](https://www.youtube.com/watch?v=YdiZa0Y3F3c), and was the culmination of an [Intel research project](https://www.intel.com/content/www/us/en/developer/articles/technical/new-threading-capabilities-in-julia-v1-3.html) implemented in Julia.

The number of threads that Julia runs with can be set through a command line flag:
```bash
julia --threads=4
```

\vscode{
    The default number of threads can be edited by adding `"julia.NumThreads": 4,` to your settings.json. This will be applied to the integrated terminal.
}

Once Julia is running, you can check if this was successful by running
```>
Threads.nthreads()
```

For asynchronous computing, use Julia's built-in interface to [`Task`s](https://docs.julialang.org/en/v1/manual/asynchronous-programming/#Basic-Task-operations) and [`Channel`s](https://docs.julialang.org/en/v1/manual/asynchronous-programming/#Communicating-with-Channels).
For distributed memory-parallel computing, Julia ships with the [`Distributed`](https://github.com/JuliaLang/Distributed.jl) standard library.
For multi-threaded computing, there are a number of options available, both in the standard library and through external packages.

* [Base.Threads](https://docs.julialang.org/en/v1/base/multi-threading/)
* [OhMyThreads.jl](https://github.com/JuliaFolds2/OhMyThreads.jl) for something else, and comes with a [translation guide](https://juliafolds2.github.io/OhMyThreads.jl/stable/translation/) between Threads.jl and this one
* [ThreadsX.jl](https://github.com/tkf/ThreadsX.jl) for parallelised base functions

## SIMD / GPU

* [LoopVectorization.jl](https://github.com/JuliaSIMD/LoopVectorization.jl) (deprecated in 1.11)
* [Tullio.jl](https://github.com/mcabbott/Tullio.jl)
* [KernelAbstractions.jl](https://github.com/JuliaGPU/KernelAbstractions.jl)

## Efficient types
\tldr{Be aware that [StaticArrays.jl](https://github.com/JuliaArrays/StaticArrays.jl) exist and learn how they work}

Using an efficient data structure is a tried and true way of improving the performance.
While users can write their own efficient implementations through officially documented [interfaces](https://docs.julialang.org/en/v1/manual/interfaces/), a number of packages containing common use cases are more tightly integrated into the Julia ecosystem.

### StaticArrays

Using [StaticArrays.jl](https://github.com/JuliaArrays/StaticArrays.jl), you can construct arrays that contain not only their type information, but also their size.
With `MArray`, `MMatrix`, and `MVector`, data is mutable as in normal arrays.
However, the corresponding `SArray`, `SMatrix` and `SVector` types are immutable, so the object does not need to be garbage collected as it can be stack-allocated.
Additionally, through multiple dispatch, statically sized arrays can have specialised, efficient methods for certain algorithms such as [QR-factorisation](https://juliaarrays.github.io/StaticArrays.jl/stable/pages/api/#LinearAlgebra.qr-Tuple{StaticArray{Tuple{N,%20M},%20T,%202}%20where%20{N,%20M,%20T}}).

`SArray`s, as stack-allocated objects like tuples, cannot be mutated, but should instead be replaced entirely, but doing so comes at almost no extra cost compared to directly editing the data of a mutable object.

```>staticarrays-example
using StaticArrays
x = [1, 2, 3]
x .= x .+ 1

sx = SA[1, 2, 3] # SA constructs an SArray
sx = sx .+ 1 # Note the = is not broadcasted
```

For a more familiar in-place update syntax for immutable data structures like `SArrays`s, you can use [Accessors.jl](https://github.com/JuliaObjects/Accessors.jl):

```>accessors-example
using Accessors
@set sx[1] = 3 # Returns a copy of data, does not update the variable
sx
@reset sx[1] = 4 # Replaces the original data with an updated copy
sx
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