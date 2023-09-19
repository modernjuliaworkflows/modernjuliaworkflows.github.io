@def title = "Writing your code"

# Writing your code

In this post, you will learn about tools to create, run and debug Julia code.

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

The most natural starting point is the [downloads](https://julialang.org/downloads/) page.
However, for additional flexibility, we recommend to use [`juliaup`](https://github.com/JuliaLang/juliaup) instead.
You can get it from the Windows store, or from the command line on Unix systems:

```bash
curl -fsSL https://install.julialang.org | sh
```

It provides [various utilities](https://github.com/JuliaLang/juliaup#using-juliaup) to download, update, organize and switch between Julia versions.
As a bonus, you no longer have to manually specify the path to your executable.

`juliaup` relies on adaptive shortcuts called "channels", which allow you to access specific Julia versions without giving their exact number.
For instance, the `release` channel will always point to the [current stable version](https://julialang.org/downloads/#current_stable_release), and the `lts` channel will always point to the [long-term support version](https://julialang.org/downloads/#long_term_support_release).
Upon installation of `juliaup`, the current stable version of Julia is downloaded and selected as the default.
This is the one you get when you run

```bash
julia
```

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

> The REPL has 4 primary modes: Julia, package (`]`), help (`?`) and shell (`;`).

The Read-Eval-Print Loop (or REPL) is the most basic way to interact with Julia, check out its [documentation](https://docs.julialang.org/en/v1/stdlib/REPL/) for details.
You can start a REPL by typing `julia` into a terminal, or by clicking on the Julia application in your computer.
It will allow you to play around with arbitrary Julia code:

```>repl-example
a, b = 1, 2;
a + b
```

This is the standard (Julian) mode of the REPL, but there are three other modes you need to know.
Each mode is entered by typing a specific character after the `julia>` prompt, and can be exited by hitting backspace after the `julia>` prompt.

### Help mode (`?`)

By pressing `?` you can obtain information and metadata about Julia objects (functions, types, etc.) or unicode symbols.
The query fetches the docstring of the object, which explains how to use it.

```?help-example
println
```

If you don't know the exact name you are looking for, type a word surrounded by quotes to see in which docstrings it pops up.

### Package mode (`]`)

By pressing `]` you access [Pkg.jl](https://github.com/JuliaLang/Pkg.jl), Julia's integrated package manager, whose [documentation](https://pkgdocs.julialang.org/v1/getting-started/) is an absolute must-read.
Pkg.jl allows you to:

* `activate` different local, shared or temporary environments;
* `add`, `update` (or `up`) and `remove` (or `rm`) packages;
* get the `status` (or `st`) of your current environment.

As an illustration, we create a new environment called `MyProject` and download the package Example.jl inside it:

```]pkg-example
activate MyProject
add Example
status
```

Note that the same keywords are also available in Julia mode:

```>pkg-example-2
using Pkg
Pkg.status()
Pkg.activate(".")
```

### Shell mode (`;`)

By pressing `;` you enter a terminal, where you can execute any bash command you want.

```;shell-example
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
In what follows, we will somnetimes mention commands and [keyboard shortcuts](https://www.julia-vscode.org/docs/stable/userguide/keybindings/) provided by this extension.
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
This is made much easier by [VSCode integration](https://www.julia-vscode.org/docs/stable/userguide/runningcode/), and here are the most important commands:

* `Julia: Start REPL` (shortcut `Alt + J` then `Alt + O`) - note that this is different from (and better than) opening a VSCode _terminal_ and running Julia.
* `Julia: Execute Code in REPL and Move` (shortcut `Shift + Enter`) - the executed code is the block containing the cursor, or the selected part if it exists

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
They are also a good fit for literate programming, where lines of code are interspersed with comments and explanations.

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

> Julia projects are entered with `]activate`, and their details are stored in `Project.toml` and `Manifest.toml`.

As we have seen, Pkg.jl is the Julia equivalent of `pip` or `conda` for Python.
It lets you [install packages](https://pkgdocs.julialang.org/v1/managing-packages/) and [manage environments](https://pkgdocs.julialang.org/v1/environments/) (collections of packages with specific versions).

Once you `]activate` a project, the packages you `]add` will be listed in two files called `Project.toml` and `Manifest.toml`.
Sharing a project between computers is as simple as sending a folder containing your code and both of these files.
Using them, the user can run `]instantiate` and Julia will recreate the state of your local environment.

* `Project.toml` contains general project information (name of the package, unique id, authors) and direct dependencies with version bounds.
* `Manifest.toml` contains the exact versions of all direct and indirect dependencies, which you can visualize with [PkgDependency.jl](https://github.com/peng1999/PkgDependency.jl).

If you haven't entered any local project, packages will be installed in the default environment, called `@v1.X` after the active version of Julia (note the `@` before the name).
Packages installed that way are available no matter which local environment is active, because of "environment stacking".
It is therefore recommended to keep the default environment very light, containing only essential development tools like Revise.jl.

Environments are also [handled by VSCode](https://www.julia-vscode.org/docs/stable/userguide/env/), if your directory contains a `Project.toml`, you will be asked whether you want to make this the default environment.
You can modify this setting by clicking the `Julia env: ...` button at the bottom.
Anytime you open a Julia REPL, it will launch within the environment you chose.

## Local packages

Once your code base grows beyond a few scripts, you may want to [create a package](https://pkgdocs.julialang.org/v1/creating-packages/) of your own.
The first advantage is that you don't need to specify the path of every file: `using MyPackage` is enough to get access to the names you choose to make public.
Furthermore, you can specify versions for your package and its dependencies, making your code easier and safer to reuse.
And of course, the Revise.jl niceties presented earlier still work, without even resorting to `includet`.
As soon as you load your package, the files containing its code will be tracked automatically.

To create a new package locally, the easy way is to use `]generate` (we will discuss a more sophisticated workflow involving GitHub in the next blog post).

```>generate-package
!isdir("MyPackage") ? Pkg.generate("MyPackage") : nothing;
```

This command initializes a simple folder with a `Project.toml` and a `src` subfolder.
The `src` subfolder contains a file `MyPackage.jl`, where a [module](https://docs.julialang.org/en/v1/manual/modules/) called `MyPackage` is defined.
Said module should contain

* the list of imported dependencies $\to$ `using MyOtherPackage`
* the list of included scripts in the correct order $\to$ `include("my_definitions.jl")`
* the list of names you want to make public $\to$ `export my_function`

To experiment with this new package, you can `]dev` it into your current environment.
Note the different commands: `]add Example` installs a specific version of a package from the general registry, while  `]dev ./MyPackage` relies on the current state of the code in the folder you point to.

```]dev-package
dev ./MyPackage
```

We can then use the one function defined in `MyPackage`:

```>using-package
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
Here are a few options to do so, all of can be added to your default environment `@v1.X` and startup file without fear.

[OhMyREPL.jl](https://github.com/KristofferC/OhMyREPL.jl) is a widely used package for syntax highlighting in the REPL.
[Term.jl](https://github.com/FedeClaudi/Term.jl) goes a bit further by offering a completely new way to display things like types and errors (see the [advanced configuration](https://fedeclaudi.github.io/Term.jl/stable/adv/adv/) to enable it by default).

[ProgressMeter.jl](https://github.com/timholy/ProgressMeter.jl) provides the macro `@showprogress`, which you can use to track `for` loops in the REPL.
[ProgressLogging.jl](https://github.com/JuliaLogging/ProgressLogging.jl) has a similar macro `@progress`, but it interfaces better with VSCode and Pluto to display the progress bar.

Finally, [AbbreviatedStackTraces.jl](https://github.com/BioTurboNick/AbbreviatedStackTraces.jl) allows you to shorten error stacktraces, which can sometimes get pretty long (although Julia 1.10 cleaned them up already).
[Suppressor.jl](https://github.com/JuliaIO/Suppressor.jl) can sometimes be handy when you need to suppress warnings or other bothersome messages.

## Logging

> Prefer logging macros to printing

Assume you want to debug a function checking whether the $n$-th [Fermat number](https://en.wikipedia.org/wiki/Fermat_number) $F_n = 2^{2^n} + 1$ is prime:

```!fermat
function fermat_prime(n)
    F = 2^(2^n) + 1
    for d in 2:isqrt(F)  # integer square root
        if F % d == 0
            return false
        end
    end
    return true
end;
```

```>fermat-test
fermat_prime(4)
fermat_prime(6)
```

Unfortunately, $F_4 = 65537$ is the largest known Fermat prime, which means $F_6$ is incorrectly classified.
Let's investigate why this happens!

As a first step, the macro `@show` lets you print local variables with their name:

```!fermat-show
function fermat_prime_show(n)
    F = 2^(2^n) + 1
    @show n 2^n F
    for d in 2:isqrt(F)
        if F % d == 0
            return false
        end
    end
    return true
end;
```

```>fermat-show-test
fermat_prime_show(4)
fermat_prime_show(6)
```

The diagnosis is a classic one: [integer overflow](https://docs.julialang.org/en/v1/manual/faq/#faq-integer-arithmetic).
Indeed, $2^{64}$ is larger than the maximum integer value in Julia:

```>typemax
typemax(Int)
```

And the solution is to call our function on "big" integers with an arbitrary number of bits:

```>fermat-show-test2
fermat_prime_show(big(6))
```

While printing might suffice to debug simple problems, we can do better.
Julia offers the logging macros `@debug`, `@info`, `@warn` and `@error`, which have several advantages over printing:

* They show the line number they were called from
* They label arguments, similar to `@show`
* They can be disabled and filtered according to source module and severity level
* They work well in multithreaded code
* They can write their output to a file

Refer to the logging [documentation](https://docs.julialang.org/en/v1/stdlib/Logging/) for more information.
In particular, note that `@debug` messages are suppressed by default.
You can enable them through the `JULIA_DEBUG` environment variable if you specify the source module name, here `Main`.

```julia-repl
julia> ENV["JULIA_DEBUG"] = Main # enable @debug logs
```

## Debugging

> Debugger.jl and Infiltrator.jl allow you to peek inside a function while its execution is paused.

The problem with logging is that you cannot interact with local variables or save them for further analysis.
The following two packages solve this issue, and they probably belong in your default environment `@v1.X`, like Revise.jl.

### Debugger.jl

[Debugger.jl](https://github.com/JuliaDebug/Debugger.jl) allows us to interrupt code execution anywhere we want, even in functions we did not write.
Using its `@enter` macro, we can enter a function call and walk through the call stack.
The REPL prompt changes to `1|debug>`, allowing you to use [custom navigation commands](https://github.com/JuliaDebug/Debugger.jl#debugger-commands) to step into and out of function calls, show local variables and set breakpoints.
Typing a backtick `` ` `` will change the prompt to `1|julia>`, indicating evaluation mode.
Any expression typed in this mode will be evaluated in the local context.
This is useful to show local variables, as demonstrated in the following example:

```julia-repl
julia> using Debugger

julia> @enter fermat_prime(6)
In fermat_prime(n) at REPL[1]:1
 1  function fermat_prime(n)
>2      F = 2^(2^n) + 1
 3      for d in 2:isqrt(F)
 4          if F % d == 0
 5              return false
 6          end

About to run: (^)(2, 6)
1|debug> n
In fermat_prime(n) at REPL[1]:1
 1  function fermat_prime(n)
 2      F = 2^(2^n) + 1
>3      for d in 2:isqrt(F)
 4          if F % d == 0
 5              return false
 6          end
 7      end

About to run: (isqrt)(1)
1|debug> n
In fermat_prime(n) at REPL[1]:1
 4          if F % d == 0
 5              return false
 6          end
 7      end
>8      return true
 9  end

About to run: return true
1|julia> F
1
```

For a more user-friendly debugging interface, Debugger.jl is [interfaced with VSCode](https://www.julia-vscode.org/docs/stable/userguide/debugging/).
Click left of a line number in an editor pane to add a _breakpoint_, which is represented by a red circle.
In the debugging pane of the Julia extension, click `Run and Debug` to start the debugger.
The program will automatically halt when it hits a breakpoint.
Using the toolbar at the top of the editor, you can then _continue_, _step over_, _step into_ and _step out_ of your code.
The debugger will open a pane showing information about the code such as local variables inside of the current function, their current values and the full call stack.

### Infiltrator.jl

[Infiltrator.jl](https://github.com/JuliaDebug/Infiltrator.jl) is a lightweight alternative to Debugger.jl, which will not slow down your code at all.
Its `@infiltrate` macro allows you to directly set breakpoints in your code.
Calling a function which hits a breakpoint will activate the Infiltrator REPL-mode
and change the prompt to `infil>`.
Typing `?` in this mode will summarize available commands.
For example, typing `@locals` in Infiltrator-mode will print local variables:

```!infiltrator
using Infiltrator

function fermat_prime_infil(n)
    F = 2^(2^n) + 1
    @infiltrate
    for d in 2:isqrt(F)
        if F % d == 0
            return false
        end
    end
    return true
end;
```

What makes Infiltrator.jl even more powerful is the `@exfiltrate` macro, which allows you to move local variables into a global storage called the `safehouse`.

```julia-repl
julia> fermat_prime_infil(6)
Infiltrating fermat_prime_infil(n::Int64)
  at REPL[2]:3

infil> F
1

infil> @exfiltrate F
Exfiltrating 1 local variable into the safehouse.

infil> @continue

true

julia> safehouse.F
1
```

More advanced debugging tools include [InteractiveCodeSearch.jl](https://github.com/tkf/InteractiveCodeSearch.jl), [InteractiveErrors.jl](https://github.com/MichaelHatherly/InteractiveErrors.jl) and [CodeTracking.jl](https://github.com/timholy/CodeTracking.jl), but we will not describe them in detail.