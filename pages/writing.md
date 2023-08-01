@def title = "Writing your code"

# Writing your code

\toc

## Installation

> TLDR: Use [juliaup]

```julia:version
#hideall
print(VERSION)
```

The official [downloads page](https://julialang.org/downloads/) is where you can get Julia's current stable release.
If you use this page, don't forget to also read the platform-specific instructions for [Windows](https://julialang.org/downloads/platform/#windows), [macOS](https://julialang.org/downloads/platform/#macos) or [Linux](https://julialang.org/downloads/platform/#linux_and_freebsd).
At the time of writing, the latest Julia version is \textoutput{version}.
But of course, new updates are released regularly, and you will need to keep up.
In addition, you may want to test your code on older versions to ensure compatibility.

Therefore, we recommend you manage Julia with a tool called [juliaup].
You can get it from the [Windows store](https://github.com/JuliaLang/juliaup#windows), or install it from the [command line](https://github.com/JuliaLang/juliaup#mac-and-linux) on Unix systems.
It provides [various utilities](https://github.com/JuliaLang/juliaup#using-juliaup) to download, update, organize and switch between Julia versions.
As a bonus, you no longer have to specify the path to your Julia executable: juliaup takes care of that for you.

The defining feature of juliaup is that it provides adaptive shortcuts called "channels", which allow you to access specific Julia versions without giving their exact number.
You only need to know two of them:

* `release`, which is bound to the [current stable release](https://julialang.org/downloads/#current_stable_release);
* `lts`, which is bound to the [long-term support version](https://julialang.org/downloads/#long_term_support_release).

For instance, you can install the long-term support version with

```bash
juliaup add lts
```

When new versions are tagged, the binding of a given channel can change, and a new executable might need to be downloaded.
If you want to catch up with the latest developments, all it takes is to run

```bash
juliaup update
```

If you want an overview of the channels installed on your computer, just use

```bash
juliaup status
```

[juliaup]: https://github.com/JuliaLang/juliaup

## REPL

> TLDR: The REPL has 4 primary modes: Julia, package (`]`), help (`?`) and shell (`;`).

The Read-Eval-Print Loop (or REPL) is the standard way to interact with Julia.
Check out its [documentation](https://docs.julialang.org/en/v1/stdlib/REPL/) for details.
You can start one by typing `julia` into a terminal, or by clicking on the Julia application in your computer.
It will allow you to play around with arbitrary Julia code:

```>
a, b = 1, 2;
a + b
```

This is the standard, Julian mode of the REPL, but it also has three other modes which expand what can be done from within Julia.
Each mode is entered by typing a specific character after the `julia>` prompt, and can be exited by hitting backspace after the `julia>` prompt.

### Help mode (`?`)

By pressing `?` you can obtain information and metadata about Julia objects and unicode symbols.
For functions, types, and variables, the query fetches things such as documentation, type fields and supertypes, and in which file the object is defined.

```?
abs
```

For unicode symbols, the query will return how to type the symbol in the REPL, which is useful when you copy-paste a symbol in without knowing its name, and fetch information about the object the symbol is bound to, just as above.

### Package mode (`]`)

By pressing `]` you access the package manager.
This allows you to:

* `add`, `update` (or `up`) and `remove` (or `rm`) packages;
* `activate` different local, global or temporary environments;
* get the `status` (or `st`) of your current environment.

```]
activate --temp
add Example
status
```

### Shell mode (`;`)

By pressing `;` you enter a terminal, where you can execute any bash command you want.

```;
echo "hello"
ls ./pages
```

## Editors

### Integrated Development Environments

> TLDR: [VSCode] has the best Julia support.

Most computer programs are just plain text files with a specific extension (in our case `.jl`).
So in theory, any text editor suffices to write and modify Julia code.
In practice, an [Integrated Development Environment](https://en.wikipedia.org/wiki/Integrated_development_environment) (or IDE) makes the experience much more pleasant.
The idea is to augment text edition with tools that are specific to software development (eg. for analyzing, running or debugging your code).

The best IDE for Julia is probably [VSCode], developed by Microsoft.
IDEs do not support most languages out of the box: they need dedicated plugins to do that.
And although it is far from perfect, the [Julia VSCode extension] is the most feature-rich and actively developed of all IDE plugins for Julia.
You can download it from the [VSCode Marketplace](https://marketplace.visualstudio.com/items?itemName=julialang.language-julia).

If you want to avoid the Microsoft ecosystem, [VSCodium](https://vscodium.com/) is a nearly bit-for-bit replacement for VSCode, but with an open source license and without the telemetry layer.
If you don't want to use VSCode at all, other options include [emacs](https://www.gnu.org/software/emacs/) and [vim](https://www.vim.org/).
Check out [JuliaEditorSupport](https://github.com/JuliaEditorSupport) to see if your favorite IDE has a Julia plugin.

[VSCode]: https://code.visualstudio.com/
[Julia VSCode extension]: https://www.julia-vscode.org/

### Notebooks

> TLDR: Jupyter or Pluto, depending on your reactivity needs

Notebooks are a popular alternative to IDEs when it comes to reasonably short and self-contained code, typically in data science.
They are also a good fit for [literate programming](https://en.wikipedia.org/wiki/Literate_programming), where lines of code are interspersed by comments and explanations.
Note that such comments are often written in [Markdown](https://en.wikipedia.org/wiki/Markdown), see the [Markdown Guide](https://www.markdownguide.org/) if you are not familiar with it.

The most well-known notebook ecosystem is [Jupyter], which supports **Ju**lia, **Pyt**hon and **R** as its three core languages.
To use it with Julia, you will need to install the [IJulia.jl](https://github.com/JuliaLang/IJulia.jl) backend.
Then, if you have also installed Jupyter, you can run this command to launch the server:

```bash
jupyter notebook
```

If you only have IJulia.jl on your system, you can run this snippet instead:

```julia-repl
julia> using IJulia

julia> notebook()
```

A pure-Julia alternative to Jupyter is given by [Pluto.jl].
Unlike Jupyter notebooks, Pluto notebooks are reactive: every time you update a single cell, all of the other cells that depend on it are also updated.
In addition, they come bundled with an exhaustive list of dependencies.
These two aspects make Pluto notebooks great for teaching, and for building fully reproducible examples.
To try them out, install the package and then run

```julia-repl
julia> using Pluto

julia> Pluto.run()
```

[Jupyter]: https://jupyter.org/
[Pluto.jl]: https://plutojl.org/

## Running code

### Manually

The two most common ways of running Julia code is by sending code to a [REPL](#REPL), or by running entire scripts from the command line.
Due to Julia's relatively long startup latency, the former method is preferred by most developers.
Using the [Julia VSCode extension], one can run the `Julia: Execute Code in REPL` command with a hotkey defaulting to `shift-enter` to send code to a REPL.
If certain code is highlighted, then it will be run, but if not, then the command will run whatever "makes sense" depending on the cursor's location.
For example, if the cursor is somewhere inside or just after a function definition, it will run the definition.

To run entire Julia scripts at once, the `Julia: Execute File in REPL` command may be preferred to opening a new REPL due to the afforementioned startup latency.
However, when keeping the same REPL open for a long time, it's common to end up with a "polluted" workspace where the definitions of certain variables, functions, and structs are different to those contained in the file.
In this case, it's possible that these previously defined objects silently affect your code in an unexpected way, perhaps by a function unintentionally referencing a global variable that would otherwise throw an error.
For this reason, it's important to strike a balance between keeping your workspace clean by resetting it and keeping it open for a long time to take advantage of previously compiled code.

One way to help with workspace tidiness is to take advantage of the [module system](#Packages) to separate the core, reusable parts of your code with the one-off parts that are only relevant for a certain script.

### Automatically

While Julia allows the specification of [startup flags] to handle pre-startup configuration such as the number of threads available and which optimisations can be performed, most Julia developers also have a [startup.jl file] which is automatically run every time a REPL is started.

In this file, users commonly load packages that affect the REPL experience such as [OhMyREPL.jl], as well as utilities such as [BenchmarkTools.jl] for benchmarking.
As well as this, it allows you to define your own helper functions and have them immediately available.

[startup flags]: https://docs.julialang.org/en/v1/manual/command-line-interface/#command-line-interface
[startup.jl file]: https://docs.julialang.org/en/v1/manual/command-line-interface/#Startup-file
[OhMyREPL.jl]: https://kristofferc.github.io/OhMyREPL.jl/stable
[BenchmarkTools.jl]: https://juliaci.github.io/BenchmarkTools.jl/stable/

## Packages

> TLDR: Pkg.jl lets you `activate` independent, reproducible environments to `add` and `remove` project-specific (versions of) packages.

Pkg.jl and the Pkg mode built in to the [REPL](#REPL) let you install packages and manage environments.
A "package" is a structured way of reusing functionality between projects and the active "environment" is responsible for determining which versions of packages to load.
When working on a project, you can create a new environment or switch to an existing one by running
```]
activate MyProject
```
Then packages you install, and their specific versions, will be noted in the high-level `Project.toml` file as well as its low-level `Manifest.toml` cousin.
Sharing a project between computers with perfect reproducibility is as simple as sending a folder containing your code as well as a `Project.toml` and `Manifest.toml` so Julia can perfectly recreate the state of packages in the local environment.
When a project is shared, the recipient can simply `instantiate` the environment and have a perfect copy.

To add packages you can use the `add` command followed by any number of packages
```]
add Term OhMyREPL
```
If you haven't `activate`d a local project, these packages will be installed in the "global environment" whose name in Pkg mode is `@v1.X`, corresponding to the version of Julia currently active.
Packages installed globally are available no matter which environment is active due to what's referred to as "environment stacking".

We can see this stack by running
```julia-repl
Base.LOAD_PATH
```
When choosing which code to load when `using Package` is called, Julia will start at the local environment referred to as `@`, then go down the stack to the global environment `@v1.X`, then finally to the standard library `@stdlib`.
As mentioned before, this means that any package installed in the global environment can be used in any project.
This is typically used for development tools that you always want available to be loaded manually or using the [`startup.jl` file](#Automatically).
Secondly, this means that you can install different versions of globally installed packages in a local project with no interference.
Finally, this also applies to the standard library, which can be treated like a third-party package without having its version tied to that of Julia itself.

### Local packages
While the Julia package ecosystem covers a *lot* of functionality, you may have your own code that you find yourself reusing between projects.
You could load this code directly with `include("path/to/file.jl")`, but to avoid writing the path each time a better solution would be to make your own local package.

# TODO: Creating, editing, and loading a new local package in a different project.
# TODO: Environments in VSCode

* [Pkg.jl](https://github.com/JuliaLang/Pkg.jl)
* stacking environments
* [environments in VSCode](https://www.julia-vscode.org/docs/stable/userguide/env/)
* Local packages

## Esthetics

* [Term.jl](https://github.com/FedeClaudi/Term.jl)
* [OhMyREPL.jl](https://github.com/KristofferC/OhMyREPL.jl)
* [AbbreviatedStackTraces.jl](https://github.com/BioTurboNick/AbbreviatedStackTraces.jl)
* [InteractiveErrors.jl](https://github.com/MichaelHatherly/InteractiveErrors.jl)
* [ProgressMeter.jl](https://github.com/timholy/ProgressMeter.jl)

## Debugging

* [Infiltrator.jl](https://github.com/JuliaDebug/Infiltrator.jl)
* [Debugger.jl](https://github.com/JuliaDebug/Debugger.jl)
* [debugging in VSCode](https://www.julia-vscode.org/docs/stable/userguide/debugging/)

## Other languages

* [C and Fortran](https://docs.julialang.org/en/v1/manual/calling-c-and-fortran-code/)
* [CondaPkg.jl](https://github.com/cjdoris/CondaPkg.jl) + [PythonCall.jl](https://github.com/cjdoris/PythonCall.jl)
* [JuliaInterop](https://github.com/JuliaInterop) ([RCall.jl](https://github.com/JuliaInterop/RCall.jl), [Cxx.jl](https://github.com/JuliaInterop/Cxx.jl))

## Getting help

* [StartHere.jl](https://github.com/JuliaCommunity/StartHere.jl)
* [community spaces](https://julialang.org/community/)
