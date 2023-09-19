@def title = "Writing your code"

# Writing your code

\toc

## Getting help

> You're not alone!

Before you write any line of code, it's good to know where to find help.
The official [help page](https://julialang.org/about/help/) is a good place to start.
In particular, the Julia [community](https://julialang.org/community/) is always happy to guide beginners.

As a rule of thumb, the [Discourse forum](https://discourse.julialang.org/) is where you should ask your questions to make the answers discoverable for future users.
If you just want to chat with someone, you should go to our very active [Slack](https://julialang.org/slack/) instead.
Some of the vocabulary used by community members may appear unfamiliar, but don't worry: [StartHere.jl](https://github.com/JuliaCommunity/StartHere.jl) gives you a good head start.

## Installation

> Use `juliaup`

The most natural starting point to install Julia onto your system is the [Julia downloads page](https://julialang.org/downloads/).
However, for additional flexibility, we recommend to use [`juliaup`](https://github.com/JuliaLang/juliaup) instead.
Here is how you can get it for your system:

1. **Windows Users:** the easiest way is to download it from the [Windows Store](https://apps.microsoft.com/store/detail/julia/9NJNWW8PVKMN?hl=en-us&gl=us&rtc=1). 
Not only should this create an application launcher for Julia on your system but you will be able to utilize `juliaup` from the Windows PowerShell.

2. **OSX or Linux Users:** execute the following `curl` and `bash` commands to install `juliaup` to your system:

```bash
curl -fsSL https://install.julialang.org | sh
```

`juliaup` provides [various utilities](https://github.com/JuliaLang/juliaup#using-juliaup) to download, update, organize and switch between different Julia versions.
As a bonus, you no longer have to manually specify the path to your executable (don't worry if "path" is an unfamiliar term -- `juliaup` manages it for you).

### `juliaup` Channels

`juliaup` relies on adaptive shortcuts called "channels", which allow you to access specific Julia versions without giving their exact version number.
For instance, the `release` channel will always point to the [current stable version](https://julialang.org/downloads/#current_stable_release), and the `lts` channel will always point to the [long-term support version](https://julialang.org/downloads/#long_term_support_release).
Upon installation of `juliaup`, the current stable release version of Julia is downloaded and selected as the default.
This is the one you get when you run `julia` in your REPL (or the one that gets called by the Julia Windows app launcher).

To use other channels, add them to `juliaup` and put a `+` in fron the of the channel name when you start Julia:

```bash
juliaup add lts
julia +lts
```

You can get an overview of the channels installed on your computer with

```bash
juliaup status
```

When new versions are tagged, the version associated with a given channel can change, which means a new executable needs to be downloaded.
If you want to catch up with the latest developments, just do

```bash
juliaup update
```

## REPL

> The Julia REPL has 4 primary modes: Julia, package (`]`), help (`?`) and shell (`;`).

The Julia Read-Eval-Print Loop (or REPL) is the most basic way to interact with Julia, check out its [documentation](https://docs.julialang.org/en/v1/stdlib/REPL/) for details.
You can start a REPL by typing `julia` into a terminal, or by clicking on the Julia application in your computer.
It will allow you to play around with arbitrary Julia code:

```>
a, b = 1, 2;
a + b
```

This is the standard (Julian) mode of the REPL, but there are three other modes you need to know.
Each mode is entered by typing a specific character after the `julia>` prompt, and can be exited by hitting backspace after the `julia>` prompt.

### Help mode (`?`)

By pressing `?` you can obtain information and metadata about Julia objects (functions, types, etc.), and unicode symbols.
The query fetches the docstring of the object, which explains how to use it.

```?
println
```

If you don't know the exact name you are looking for, type a word surrounded by quotes to see in which docstrings it pops up.

### Package mode (`]`)

By pressing `]` you access [Pkg.jl](https://github.com/JuliaLang/Pkg.jl), Julia's integrated package manager, whose [documentation](https://pkgdocs.julialang.org/v1/getting-started/) is an absolute must-read.
Pkg.jl allows you to:

* `activate` different local, global or temporary environments;
* `add`, `update` (or `up`) and `remove` (or `rm`) packages;
* get the `status` (or `st`) of your current environment.

As an illustration, we create a new environment called `MyProject` and download the package Example.jl inside it:

```]
activate MyProject
add Example
status
```

### Shell mode (`;`)

By pressing `;` you enter a terminal, where you can execute any bash command you want.

```;
echo "hello"
ls ./pages
```

## Editor

> VSCode has the best Julia support.

Most computer programs are just plain text files with a specific extension (in our case `.jl`).
So in theory, any text editor suffices to write and modify Julia code.
In practice, an Integrated Development Environment (or IDE) makes the experience much more pleasant, thanks to code-related utilities and language-specific plugins.

The best IDE for Julia is [Visual Studio Code](https://code.visualstudio.com/), or VSCode, developed by Microsoft.
Indeed, the [Julia VSCode extension](https://www.julia-vscode.org/) is the most feature-rich of all Julia IDE plugins.
You can download it from the VSCode Marketplace.
In what follows, we will often mention commands and keyboard shortcuts provided by this extension.
But the only shortcut you need to remember is `Ctrl + Shift + P` (or `Cmd + Shift + P` on Mac): this opens the VSCode command palette, in which you can search for any command.
Type "julia" in the command palette to see what you can do.

Assuming you want to avoid the Microsoft ecosystem, [VSCodium](https://vscodium.com/) is a nearly bit-for-bit replacement for VSCode, but with an open source license and without telemetry.
If you don't want to use VSCode at all, other options include [emacs](https://www.gnu.org/software/emacs/) and [vim](https://www.vim.org/).
Check out [JuliaEditorSupport](https://github.com/JuliaEditorSupport) to see if your favorite IDE has a Julia plugin.
The available functionalities should be roughly similar to those of VSCode, at least for the basic aspects like running code.

## Running code

> Open a REPL and run all your code there interactively

You can execute a Julia script from your terminal, but in most cases that is not what you want to do.

```bash
julia myfile.jl
```

Julia has a rather high startup, load and compilation latency.
If you only use scripts, you will pay this cost every time you run a slightly modified version of your code.
That is why many Julia developers fire up a REPL at the beginning of the day and run all of their code there, chunk by chunk, in an interactive way.
This is made much easier by IDE integration, and here are the relevant [VSCode commands](https://www.julia-vscode.org/docs/stable/userguide/runningcode/):

* `Julia: Start REPL` - note that this is different from (and better than) opening a VSCode _terminal_ and running Julia.
* `Julia: Execute Code in REPL and Move` (shortcut `Shift + Enter`) - as in Jupyter, the code that gets executed is the block containing the cursor, or the selected part if it exists

Once your project grows, you will find yourself several files containing type and function definitions
It is rather tedious to re-run `include("my_definitions.jl")` for every small change, which is why [Revise.jl](https://github.com/timholy/Revise.jl) was created.
This package is used by a vast majority of Julia developers to track code modifications automatically.
If you are only writing scripts (and not full packages), all you need to do is

1. start your Julia session with `using Revise`
2. replace every `include` with `includet` (for "include + track")

When keeping the same REPL open for a long time, it's common to end up with a "polluted" workspace where the definitions of certain variables or functions have been overwritten in unexpected ways.
This, along with other events like `struct` redefinitions, might force you to restart your REPL now and again, and that's okay.

## Notebooks

> Jupyter or Pluto, depending on your reactivity needs

Notebooks are a popular alternative to IDEs when it comes to short and self-contained code, typically in data science.
They are also a good fit for literate programming, where lines of code are interspersed by comments and explanations.

The most well-known notebook ecosystem is [Jupyter](https://jupyter.org/), which supports Julia, Python and R as its three core languages.
To use it with Julia, you will need to install the [IJulia.jl](https://github.com/JuliaLang/IJulia.jl) backend.
Then, if you have also [installed Jupyter](https://jupyter.org/install) with `pip install jupyterlab`, you can run this command to launch the server:

```bash
jupyter lab
```

If you only have IJulia.jl on your system, you can run this snippet instead:

```julia-repl
julia> using IJulia

julia> IJulia.notebook()
```

A pure-Julia alternative to Jupyter is given by [Pluto.jl](https://plutojl.org/).
Unlike Jupyter notebooks, Pluto notebooks are

* Reactive: when you update a cell, the other cells depending on it are updated.
* Reproducible: they come bundled with an exhaustive list of dependencies.

To try them out, install the package and then run

```julia-repl
julia> using Pluto

julia> Pluto.run()
```

## Environments

> Julia projects are entered with `]activate`, and their details are stored in the `Project.toml` and `Manifest.toml`.

As we have seen, Pkg.jl is the Julia equivalent of `pip` or `conda` for Python.
It lets you [install packages](https://pkgdocs.julialang.org/v1/managing-packages/) and [manage environments](https://pkgdocs.julialang.org/v1/environments/) (collections of packages with specific versions).
It can be used from the REPL, either in package mode (prefixing the first command with a `]`), or directly in Julia mode with the same keywords:

```>
using Pkg
Pkg.status()
```

Once you `]activate` a project, the packages you `]add` will be listed in two files called `Project.toml` and `Manifest.toml`.
Sharing a project between computers is as simple as sending a folder containing your code and both of these files.
Using them, the user can run `]instantiate MyPackage` and Julia will recreate the state of your local environment.

* `Project.toml` contains general project information (name of the package, unique id, authors) and direct dependencies with version bounds.
* `Manifest.toml` contains the exact versions of all direct and indirect dependencies, which you can visualize with [PkgDependency.jl](https://github.com/peng1999/PkgDependency.jl).

If you haven't entered any local project, packages will be installed in the "global environment", called `@v1.X` after the active version of Julia (note the `@` before the name).
Packages installed globally are available no matter which local environment is active, because of "environment stacking".
It is therefore recommended to keep the global environment very light, containing only essential development tools like Revise.jl.

In VSCode, if your directory contains a `Project.toml`, you will be asked whether you want to make this the default environment.
You can modify this setting by clicking the `Julia env: ...` button at the bottom.
Anytime you open a Julia REPL, it will launch within the environment you chose.

## Local packages

Once your code base grows even bigger than a few scripts, you may want to [create a package](https://pkgdocs.julialang.org/v1/creating-packages/) of your own.
The first advantage is that you don't need to specify the path of every file: `using MyPackage` is enough to get access to the names you choose to make public.
Furthermore, you can specify versions for your package and its dependencies, making your code easier and safer to reuse.
And of course, the Revise.jl niceties presented earlier still work, without even resorting to `includet`.
As soon as you load your package, the files containing its code will be tracked automatically.

To create a new package locally, the easy way is to use `]generate` (we will discuss a more sophisticated workflow involving GitHub in the next blog post).
This command initializes a simple folder with a `Project.toml` and a `src` subfolder.
The `src` subfolder contains a file `MyPackage.jl`, where a [module](https://docs.julialang.org/en/v1/manual/modules/) called `MyPackage` is defined.

```>
!isdir("MyPackage") ? Pkg.generate("MyPackage") : nothing;
```

This module should contain

* the list of imported dependencies $\to$ `using MyOtherPackage`
* the list of included scripts in the correct order $\to$ `include("my_definitions.jl")`
* the list of names you want to make public $\to$ `export my_function`

We can then add our brand new package to the current project.
Note that we do it with a different command, `]dev path` instead of `]add name`, because we want to depend on the current state of the code in `MyPackage` (rather than a specific release from a GitHub repository).

```]
dev ./MyPackage
status
```

We can indeed use the one function defined in `MyPackage`:

```>
using MyPackage
MyPackage.greet()
```

## Configuration

Julia accepts [startup flags](https://docs.julialang.org/en/v1/manual/command-line-interface/#command-line-interface) to handle settings such as the number of threads available or the environment in which it launches.
In addition, most Julia developers also have a [startup file](https://docs.julialang.org/en/v1/manual/command-line-interface/#Startup-file) which is run automatically every time the language is started.
It is located at `.julia/config/startup.jl`.

The basic component that everyone puts in the startup file is Revise.jl:

```julia
try
    using Revise
catch e
    @warn "Error initializing Revise"
end
```

In addition, users commonly load packages that affect the REPL experience, as well as esthetic, benchmarking or profiling utilities: [StartupCustomizer.jl](https://github.com/abraemer/StartupCustomizer.jl) can help you set them up.
More generally, the startup file allows you to define your own favorite helper functions and have them immediately available in every Julia session.

## Esthetics

Now that you know your way around the Julia REPL, perhaps you want to make it a little prettier.
Here are a few options to do so, all of can be added to your global environment `@v1.X` and startup file without fear.

[OhMyREPL.jl](https://github.com/KristofferC/OhMyREPL.jl) is a widely used package for syntax highlighting in the REPL.
[Term.jl](https://github.com/FedeClaudi/Term.jl) goes a bit further by offering a completely new way to display things like types and errors (see the [advanced configuration](https://fedeclaudi.github.io/Term.jl/stable/adv/adv/) to enable it by default).

[ProgressMeter.jl](https://github.com/timholy/ProgressMeter.jl) provides the macro `@showprogress`, which you can use to track `for` loops in the REPL.
[ProgressLogging.jl](https://github.com/JuliaLogging/ProgressLogging.jl) has a similar macro `@progress`, but it interfaces better with VSCode and Pluto to display the progress bar.

Finally, [AbbreviatedStackTraces.jl](https://github.com/BioTurboNick/AbbreviatedStackTraces.jl) allows you to shorten error stacktraces, which can sometimes get pretty long (although Julia 1.10 cleaned them up already).
[Suppressor.jl](https://github.com/JuliaIO/Suppressor.jl) can sometimes be handy when you need to suppress warnings or other bothersome messages.

## Debugging

> Prefer logging to printing, and if you need more firepower use Debugger.jl or Infiltrator.jl.

### Logging

Assume you want to debug the following function, which is supposed to compute the 
sum of divisors excluding the number itself:

```julia
function sum_of_divisors(n)
    divisors = filter(x -> n % x == 0, 1:n)
    return sum(divisors)
end
```

```>
sum_of_divisors(6) # should return 1 + 2 + 3
```

Can you spot the issue with this function?
If not, the macro `@show` or the function `println` let you print local variables inside of a function:

```julia:debugshow
function sum_of_divisors(n)
    divisors = filter(x -> n % x == 0, 1:n)
    @show divisors
    return sum(divisors)
end
```

```>
sum_of_divisors(6)
```

While printing might suffice to debug simple problems, we can do better.
Julia offers the logging macros `@debug`, `@info`, `@warn` and `@error`, which have several advantages over printing:

* They show the line number they were called from
* They label arguments, similar to `@show`
* They can be disabled and filtered according to source module and severity level 
* They work well in multithreaded code
* They can write their output to a file

By default, `@debug` messages are suppressed. 
You can enable them through the `JULIA_DEBUG` environment variable 
by specifying the source module name, e.g. `Main`. 

```julia:debuglogging
function sum_of_divisors(n)
    divisors = filter(x -> n % x == 0, 1:n)
    @debug "sum_of_divisors" n divisors
    return sum(divisors)
end
```

<!-- Live REPL mode doesn't print debug output -->
```julia-repl
julia> ENV["JULIA_DEBUG"] = Main # enable @debug logs
Main

julia> sum_of_divisors(6)
┌ Debug: sum_of_divisors
│   n = 6
│   divisors =
│    4-element Vector{Int64}:
│     1
│     2
│     3
│     6
└ @ Main REPL[1]:3
12
```

For scripts, you can prefix your command-line call to `julia` with environment variables, 
e.g. `JULIA_DEBUG=Main julia myscript.jl`.
Refer to the logging [documentation](https://docs.julialang.org/en/v1/stdlib/Logging/) for more information.

### Debugger.jl

The problem with the previous methods is that printing does not allow you to interact with the local variables inside the function.
And once it is done executing, you lose all of this context forever.

To remedy that, [Debugger.jl](https://github.com/JuliaDebug/Debugger.jl) allows us to interrupt the execution anywhere we want.
Using its `@enter` macro, we can enter a function call and walk through the call stack.
The REPL prompt changes to `1|debug>`, allowing you to use [custom navigation commands](https://github.com/JuliaDebug/Debugger.jl#debugger-commands) to step into and out of function calls, show local variables and set breakpoints.
Typing a backtick `` ` `` will change the prompt to `1|julia>`, indicating evaluation mode. Any expression typed in this mode will be evaluated in the local context.
This is useful to show local variables, as demonstrated in the following example:

```julia-repl
julia> @enter sum_of_divisors(6)
In sum_of_divisors(n) at REPL[3]:1
 1  function sum_of_divisors(n)
>2      divisors = filter(x -> n % x == 0, 1:n)
 3      return sum(divisors)
 4  end

About to run: (typeof)(6)
1|debug> n # n: step to next line
In sum_of_divisors(n) at REPL[3]:1
 1  function sum_of_divisors(n)
 2      divisors = filter(x -> n % x == 0, 1:n)
>3      return sum(divisors)
 4  end

About to run: (sum)([1, 2, 3, 6])
1|julia> divisors # type `, then variable name
4-element Vector{Int64}:
 1
 2
 3
 6
```

For a more user-friendly debugging interface, Debugger.jl is [integrated](https://www.julia-vscode.org/docs/stable/userguide/debugging/) into the VSCode extension.
Click left of a line number in an editor pane to add a *breakpoint*, which is represented by a red circle.
In the debugging pane of the Julia extension, click `Run and Debug` to start the debugger.
The program will automatically halt when it hits a breakpoint.
Using the toolbar at the top of the editor, you can then *continue*, *step over*, *step into* and *step out* of your code.
The debugger will open a pane showing information about the code such as local variables inside of the current function, their current values and the full call stack.

### Infiltrator.jl

[Infiltrator.jl](https://github.com/JuliaDebug/Infiltrator.jl) is a lightweight alternative to Debugger.jl, which means it will not slow down your code at all.
Its `@infiltrate` macro allows you to directly set breakpoints in your code.
Calling a function which hits a breakpoint will activate the Infiltrator REPL-mode
and change the prompt to `infil>`.
Typing `?` in this mode will summarize available commands.
For example, typing `@locals` in Infiltrator-mode will print local variables:

```julia
using Infiltrator 

function sum_of_divisors(n)
    divisors = filter(x -> n % x == 0, 1:n)
    @infiltrate
    return sum(divisors)
end
```

```julia-repl
julia> sum_of_divisors(6)
Infiltrating (on thread 1) sum_of_divisors(n::Int64)
  at REPL[4]:3

infil> @locals
- n::Int64 = 6
- divisors::Vector{Int64} = [1, 2, 3, 6]
```

What makes Infiltrator.jl even more powerful is the `@exfiltrate` macro, which allows you to move local variables into a global storage called the `safehouse`.

```julia-repl
infil> @exfiltrate divisors
Exfiltrating 1 local variable into the safehouse.

infil> @continue

12

julia> safehouse.divisors
4-element Vector{Int64}:
 1
 2
 3
 6
```

More advanced debugging tools include [InteractiveCodeSearch.jl](https://github.com/tkf/InteractiveCodeSearch.jl), [InteractiveErrors.jl](https://github.com/MichaelHatherly/InteractiveErrors.jl) and [CodeTracking.jl](https://github.com/timholy/CodeTracking.jl), but we will not describe them in detail.
